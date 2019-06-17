class CreateGlacierFileArchiveJoinTable < ActiveRecord::Migration[5.0]
  def change
    create_join_table :application_data_backups, :glacier_file_archives, :force => true
  end
end
