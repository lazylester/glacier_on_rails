class CreateFakeModels < ActiveRecord::Migration[5.0]
  def change
    create_table :fake_models do |t|
      t.string :file_id
      t.timestamps
    end
  end
end
