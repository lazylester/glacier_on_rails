class AddApplicationDataBackupIdToGlacierArchives < ActiveRecord::Migration[5.0]
  def change
    add_column :glacier_archives, :application_data_backup_id, :integer
  end
end
