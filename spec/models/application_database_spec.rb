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
    ApplicationDatabase.save_to_file( Rails.root.join('tmp','sql_test.sql') )
  end

  it "file should contain database contents" do
    File.read( Rails.root.join('tmp','sql_test.sql')).should match "Table structure for table `test`"
  end

  after do
    File.delete(Rails.root.join('tmp','sql_test.sql'))
  end
end

describe ".zip_and_save_to_file" do
  before do
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS `test`;")
    ActiveRecord::Base.connection.create_table :test do |t|
      t.column :foo, :string
    end
    ApplicationDatabase.zip_and_save_to_file( Rails.root.join('tmp','sql_test.sql.gz') )
  end

  it "file should contain database contents" do
    system("gunzip #{ Rails.root.join('tmp','sql_test.sql.gz')}")
    File.read( Rails.root.join('tmp','sql_test.sql')).should match "Table structure for table `test`"
  end

  after do
    ['sql_test.sql','sql_test.sql.gz'].each do |filename|
      file = Rails.root.join('tmp',filename)
      File.delete(file) if File.exists? file
    end
  end
end

describe ".restore_from_file" do
  before do
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

describe ".restore_from_zipfile" do
  before do
    sql =<<-SQL
      drop table if exists `test`;
      create table test ( foo varchar(255));
      insert into test set foo = 'bar';
    SQL
    file = Rails.root.join('tmp','sql_test.sql')
    File.write(file, sql)
    system("gzip #{file}")
    ApplicationDatabase.restore_from_zipfile(BackupFile.new(:filename => file.to_s + ".gz"))
  end

  it "should restore the database contents from file" do
    ActiveRecord::Base.connection.execute("select * from test").first[0].should == 'bar'
  end

  after do
    ['sql_test.sql','sql_test.sql.gz'].each do |filename|
      file = Rails.root.join('tmp',filename)
      File.delete(file) if File.exists? file
    end
  end
end
