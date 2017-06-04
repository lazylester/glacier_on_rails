class AddTypeToGlacierArchives < ActiveRecord::Migration[5.0]
  def change
    add_column :glacier_archives, :type, :string
  end
end
