require 'glacier_on_rails/config'

class AwsBackend
  class ArchiveRetrievalNotReady < StandardError; end
  class Config < GlacierOnRails::Config; end
  include Singleton

  attr_accessor :client, :error_message

  def initialize
    @client = Aws::Glacier::Client.new(:region => Config.aws_region, :credentials => AwsBackend.credentials)
    unless vault_list.map(&:vault_name).include?(::SITE_NAME)
      @client.create_vault({:account_id => "-", :vault_name => ::SITE_NAME})
    end
  rescue => e
    AwsLog.error "Failed to initialize AwsBackend: #{e.class.name}: #{e.message}"
    raise
  end

  def self.credentials
    Aws::SharedCredentials.new(:profile_name => Config.profile_name)
  end

  def vault_list
    vault_list_info = @client.list_vaults({:account_id => "-"})
    vault_list_info.vault_list
  end

  def delete_archive(archive)
    begin
      response = client.delete_archive({
        account_id: "-",
        archive_id: archive.archive_id,
        vault_name: ::SITE_NAME
      })
      AwsLog.info "Delete archive response: #{response}"
      response
    rescue Aws::Glacier::Errors::ServiceError => e
      AwsLog.error "Failed to delete archive with: #{e.class}: #{e.message}"
    end
  end

  def create_archive(archive_contents)
    description = "backup of postgres database"
    begin
      resp = client.upload_archive({
        account_id: "-",
        archive_description: description,
        body: archive_contents,
        checksum: checksum(archive_contents),
        vault_name: ::SITE_NAME
      })
      AwsLog.info "Create archive response: #{resp}"
      resp
    rescue Aws::Glacier::Errors::ServiceError => e
      self.error_message = "Failed to create archive with: #{e.class}: #{e.message}"
      AwsLog.error error_message
      false
    end
  end

  # archive is a GlacierArchive instance from the database
  # response looks like this:
  # <struct Aws::Glacier::Types::InitiateJobOutput location="/918359762546/vaults/demo/jobs/krCLWk6m7NJWppiy2SxdhP60f98PdrdaZBfhdDTZufrAkoh-ikrvb_NA0Q1vg2WcAhzZLL92kiwjOijUEDh0U7X09YQK", job_id="krCLWk6m7NJWppiy2SxdhP60f98PdrdaZBfhdDTZufrAkoh-ikrvb_NA0Q1vg2WcAhzZLL92kiwjOijUEDh0U7X09YQK">
  def retrieve_archive(archive)
    response = client.initiate_job({ account_id: "-", # required
                          vault_name: ::SITE_NAME, # required
                          job_parameters: {
                            type: "archive-retrieval", # valid types are "archive-retrieval" and "inventory-retrieval"
                            archive_id: archive.archive_id,
                            description: "put anything here",
                            sns_topic: SnsSubscription::Topic_ARN,
                            tier: "Standard"# it's the default, but put it here to be explicit
                          }
                        })
    AwsLog.info "Retrieve archive response: #{response}"
    response
  rescue Aws::Glacier::Errors::ServiceError => e
    self.error_message = "Failed to initiate archive retrieval with: #{e.class}: #{e.message}"
    AwsLog.error error_message
    false
  end

  # archive is a GlacierArchive instance from the database
  def get_job_output(archive)
    raise ArchiveRetrievalNotReady unless  archive.retrieval_status == 'ready'
    params = {
      :response_target => filepath(archive),
      :account_id => '-',
      :vault_name => ::SITE_NAME,
      :job_id => archive.archive_retrieval_job_id
    }
    AwsLog.info("AWS Backend get job output request with: #{params}")
    resp = client.get_job_output(params)
    AwsLog.info("AWS Backend response to get job output request: #{resp}")
    resp
  rescue ArchiveRetrievalNotReady
    AwsLog.error "Get job output failed, archive status is not 'ready'"
    false
  end

  private

  def checksum(contents)
    tree_hash = Aws::TreeHash.new
    tree_hash.update(contents)
    tree_hash.digest
  end

  def filepath(archive)
    path = archive.backup_file
    FileUtils.makedirs(File.dirname(path))
    path
  end

end
