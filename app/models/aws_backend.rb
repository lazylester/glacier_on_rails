class AwsBackend
  Region = 'us-east-1'
  ProfileName = 'default'
  attr_accessor :glacier

  def initialize
    @glacier = Aws::Glacier::Client.new(:region => Region, :credentials => AwsBackend.credentials)
    unless vault_list.map(&:vault_name).include?(::SITE_NAME)
      @glacier.create_vault({:account_id => "-", :vault_name => ::SITE_NAME})
    end
  end

  def self.credentials
    credentials = Aws::SharedCredentials.new(:profile_name => ProfileName)
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
    description = "my first glacier archive"
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

  def retrieve_db_archive
    resp = glacier.initiate_job({ account_id: "-", # required
                                  vault_name: ::SITE_NAME, # required
                                  job_parameters: {
                                    #format: "string", # we don't specify output format, take what we get
                                    type: "archive-retrieval", # valid types are "archive-retrieval" and "inventory-retrieval"
                                    archive_id: GlacierArchive.first.archive_id,
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

  private

  def checksum(contents)
    tree_hash = Aws::TreeHash.new
    tree_hash.update(contents)
    tree_hash.digest
  end

  def default_filename
    datestamp = "backups_"+Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    Dir.mkdir(BACKUP_DIR) unless File.exists?(BACKUP_DIR)
    new_filename = "#{datestamp}_#{Rails.env}_dump.sql.gz"
    full_file_path = BACKUP_DIR + new_filename
    file = File.new(full_file_path, "w")
  end
end
