class ApplicationDataBackup < ActiveRecord::Base
  has_one :glacier_db_archive
  has_and_belongs_to_many :glacier_file_archives, association_foreign_key: 'glacier_file_archive_id', join_table: 'application_data_backups_glacier_file_archives'

  def create_archive
    create_glacier_db_archive # saves the ApplicationDataBackup instance if it was not already persisted
    glacier_file_archives << GlacierFileArchive.all!
  end
end
