require 'spec_helper'

#describe ".extract_contents" do
  #before do
    #ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS test")
    #ActiveRecord::Base.connection.create_table(:test) { |t| t.column(:foo, :string) }
  #end

  #it "file should contain database contents" do
    #expect(ApplicationDatabase.new.extract_contents).to match "PostgreSQL database dump complete"
  #end
#end

describe ".save_to_file" do
  before do
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS test")
    ActiveRecord::Base.connection.create_table :test do |t|
      t.column :foo, :string
    end
    ApplicationDatabase.new.save_to_file( Rails.root.join('tmp','sql_test.sql') )
  end

  it "file should contain database contents" do
    expect(File.read( Rails.root.join('tmp','sql_test.sql'))).to match "PostgreSQL database dump complete"
  end

  after do
    File.delete(Rails.root.join('tmp','sql_test.sql'))
  end
end

describe ".zip_and_save_to_file" do
  before do
    ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS test")
    ActiveRecord::Base.connection.create_table :test do |t|
      t.column :foo, :string
    end
    ApplicationDatabase.new.zip_and_save_to_file(File.new( Rails.root.join('tmp','sql_test.sql.gz'),'w') )
  end

  it "file should contain database contents" do
    system("gunzip #{ Rails.root.join('tmp','sql_test.sql.gz')}")
    expect(File.read( Rails.root.join('tmp','sql_test.sql'))).to match "PostgreSQL database dump complete"
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
      drop table if exists test;
      create table test (  foo varchar(255) );
      insert into test (foo) values ( 'bar');
    SQL
    file = Rails.root.join('tmp','sql_test.sql')
    File.write(file, sql)
    ApplicationDatabase.new.restore_from_file(DbBackup.new(:filename => file))
  end

  it "should restore the database contents from file" do
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
  end

  after do
    File.delete(Rails.root.join('tmp','sql_test.sql'))
  end
end

describe ".restore_from_zipfile" do
  before do
    sql =<<-SQL
      drop table if exists test;
      create table test ( foo varchar(255));
      insert into test set foo = 'bar';
    SQL
    file = Rails.root.join('tmp','sql_test.sql')
    File.write(file, sql)
    system("gzip #{file}")
    ApplicationDatabase.new.restore_from_zipfile(DbBackup.new(:filename => file.to_s + ".gz"))
  end

  it "should restore the database contents from file" do
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
  end

  after do
    ['sql_test.sql','sql_test.sql.gz'].each do |filename|
      file = Rails.root.join('tmp',filename)
      File.delete(file) if File.exists? file
    end
  end
end
