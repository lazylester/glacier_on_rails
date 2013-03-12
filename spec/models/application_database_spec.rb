require 'spec_helper'

describe ".extract_contents" do
  before do
    ActiveRecord::Base.connection.drop_table :test
    ActiveRecord::Base.connection.create_table :test do |t|
      t.column :foo, :string
    end
  end

  it "file should contain database contents" do
    ApplicationDatabase.extract_contents.should match "Table structure for table `test`"
  end
end

describe ".save_to_file" do
  before do
    ActiveRecord::Base.connection.drop_table :test
    ActiveRecord::Base.connection.create_table :test do |t|
      t.column :foo, :string
    end
  end

  it "file should contain database contents" do
    ApplicationDatabase.extract_contents.should match "Table structure for table `test`"
  end
end
