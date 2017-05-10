class AwsBackend
  class ArchiveRetrievalNotPending < StandardError; end
  class ArchiveRetrievalNotReady < StandardError; end

  Region = 'us-east-1'
  ProfileName = 'default'
  ArchiveRetrievalTmpFile = Rails.root.join('tmp','aws','archive_tmp_file.gz').to_s

  attr_accessor :glacier

  def initialize
    @glacier = Aws::Glacier::Client.new(:region => Region, :credentials => AwsBackend.credentials)
    unless vault_list.map(&:vault_name).include?(::SITE_NAME)
      @glacier.create_vault({:account_id => "-", :vault_name => ::SITE_NAME})
    end
  end

  def self.credentials
    Aws::SharedCredentials.new(:profile_name => ProfileName)
  end

  def vault_list
    vault_list_info = @glacier.list_vaults({:account_id => "-"})
    vault_list_info.vault_list
  end

  def create_file_archive
    # create an aws archive that contains all the docs saved by the refile gem
  end

  def create_db_archive
    db = ApplicationDatabase.new
    archive_contents = db.zipped_contents
    description = "backup of postgres database"
    begin
      resp = glacier.upload_archive({
        account_id: "-",
        archive_description: description,
        body: archive_contents,
        checksum: checksum(archive_contents),
        vault_name: ::SITE_NAME,
      })
      GlacierArchive.create(resp.to_h.merge({:description => description }))
    rescue Aws::Glacier::Errors::ServiceError
      puts "Aws::Glacier error, archive not saved" # for now do this, later something else
    end
  end

  # archive is a GlacierArchive instance from the database
  def retrieve_db_archive(archive)
    resp = glacier.initiate_job({ account_id: "-", # required
                                  vault_name: ::SITE_NAME, # required
                                  job_parameters: {
                                    #format: "string", # we don't specify output format, take what we get
                                    type: "archive-retrieval", # valid types are "archive-retrieval" and "inventory-retrieval"
                                    archive_id: archive.archive_id,
                                    description: "put anything here",
                                    sns_topic: SnsSubscription::Topic_ARN,
                                    #retrieval_byte_range: "string",
                                    tier: "Standard"# it's the default, but put it here to be explicit
                                    #inventory_retrieval_parameters: {
                                      #start_date: Time.now,
                                      #end_date: Time.now,
                                      #limit: "string",
                                      #marker: "string",
                                    #}
                                  }
                                })

    #=> {:job_id => string, :location => string}
  end

  # archive is a GlacierArchive instance from the database
  def get_job_info(archive)
    raise ArchiveRetrievalNotPending unless archive.archive_retrieval_job_id
    glacier.describe_job({:account_id => '-',
                          :vault_name => ::SITE_NAME,
                          :job_id => archive.archive_retrieval_job_id})
  end

  # archive is a GlacierArchive instance from the database
  def get_job_output(archive)
    raise ArchiveRetrievalNotPending unless archive.archive_retrieval_job_id
    raise ArchiveRetrievalNotReady unless retrieval_ready? archive
    FileUtils.makedirs(File.dirname(ArchiveRetrievalTmpFile)) unless File.exists?(File.dirname(ArchiveRetrievalTmpFile))
    resp = glacier.get_job_output({
      :response_target => ArchiveRetrievalTmpFile,
      :account_id => '-',
      :vault_name => ::SITE_NAME,
      :job_id => archive.archive_retrieval_job_id
    })
  end

  # archive is a GlacierArchive instance from the database
  def retrieval_ready?(archive)
    raise ArchiveRetrievalNotPending unless archive.archive_retrieval_job_id
    job_info = get_job_info(archive)
    job_info.completed
  end

  private

  def checksum(contents)
    tree_hash = Aws::TreeHash.new
    tree_hash.update(contents)
    tree_hash.digest
  end

end
