class AddFilenameToGlacierArchive < ActiveRecord::Migration[5.0]
  def change
    add_column :glacier_archives, :filename, :string
  end
end
