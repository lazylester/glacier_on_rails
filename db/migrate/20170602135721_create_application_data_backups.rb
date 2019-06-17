class CreateApplicationDataBackups < ActiveRecord::Migration[5.0]
  def change
    create_table :application_data_backups, :force => true do |t|
      t.timestamps
    end
  end
end
