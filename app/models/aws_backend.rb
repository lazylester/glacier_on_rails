require 'get_back/config'

class AwsBackend
  class ArchiveRetrievalNotReady < StandardError; end
  class Config < GetBack::Config; end

  attr_accessor :client

  def initialize
    @client = Aws::Glacier::Client.new(:region => Config.aws_region, :credentials => AwsBackend.credentials)
    unless vault_list.map(&:vault_name).include?(::SITE_NAME)
      @client.create_vault({:account_id => "-", :vault_name => ::SITE_NAME})
    end
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
      resp
    rescue Aws::Glacier::Errors::ServiceError => e
      AwsLog.error "Failed to create archive with: #{e.class}: #{e.message}"
    end
  end

  # archive is a GlacierArchive instance from the database
  def retrieve_archive(archive)
    resp = client.initiate_job({ account_id: "-", # required
                                  vault_name: ::SITE_NAME, # required
                                  job_parameters: {
                                    type: "archive-retrieval", # valid types are "archive-retrieval" and "inventory-retrieval"
                                    archive_id: archive.archive_id,
                                    description: "put anything here",
                                    sns_topic: SnsSubscription::Topic_ARN,
                                    tier: "Standard"# it's the default, but put it here to be explicit
                                  }
                                })

    #response looks like this:
    #<struct Aws::Glacier::Types::InitiateJobOutput location="/918359762546/vaults/demo/jobs/krCLWk6m7NJWppiy2SxdhP60f98PdrdaZBfhdDTZufrAkoh-ikrvb_NA0Q1vg2WcAhzZLL92kiwjOijUEDh0U7X09YQK", job_id="krCLWk6m7NJWppiy2SxdhP60f98PdrdaZBfhdDTZufrAkoh-ikrvb_NA0Q1vg2WcAhzZLL92kiwjOijUEDh0U7X09YQK">
  end

  # archive is a GlacierArchive instance from the database
  #def get_job_info(archive)
    #client.describe_job({:account_id => '-',
                          #:vault_name => ::SITE_NAME,
                          #:job_id => archive.archive_retrieval_job_id})
  #end

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

  # archive is a GlacierArchive instance from the database
  #def retrieval_ready?(archive)
    #job_info = get_job_info(archive)
    #job_info.completed
  #end

  private

  def checksum(contents)
    tree_hash = Aws::TreeHash.new
    tree_hash.update(contents)
    tree_hash.digest
  end

  def filepath(archive)
    path = archive.local_filepath
    FileUtils.makedirs(File.dirname(path))
    path
  end

end
