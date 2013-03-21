require 'spec_helper'

describe ".extract_contents" do
  before do
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS `test`;")
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
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS `test`;")
    ActiveRecord::Base.connection.create_table :test do |t|
      t.column :foo, :string
    end
  end

  it "file should contain database contents" do
    ApplicationDatabase.extract_contents.should match "Table structure for table `test`"
  end
end

describe ".restore_from_file" do
  before do
    BACKUP_DIR = Rails.root.join('tmp')
    sql =<<-SQL
      drop table if exists `test`;
      create table test ( foo varchar(255));
      insert into test set foo = 'bar';
    SQL
    file = Rails.root.join('tmp','sql_test.sql')
    File.write(file, sql)
    ApplicationDatabase.restore_from_file(BackupFile.new(:filename => file))
  end

  it "should restore the database contents from file" do
    ActiveRecord::Base.connection.execute("select * from test").first[0].should == 'bar'
  end

  after do
    File.delete(Rails.root.join('tmp','sql_test.sql'))
  end
end
