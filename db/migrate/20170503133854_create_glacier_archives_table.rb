class CreateGlacierArchivesTable < ActiveRecord::Migration[5.0]
  def change
    create_table :glacier_archives, :force => true do |t|
      t.text :description
      t.text :archive_id
      t.text :checksum
      t.text :location
      t.timestamps
    end
  end
end
