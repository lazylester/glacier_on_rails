require 'spec_helper'
# helpers are all required in spec helper

describe "PostgresAdapter#contents dependence on password file ~/.pgpass" do
  before do
    @config = ActiveRecord::Base.configurations[Rails.env].dup
  end
  after do
    ActiveRecord::Base.configurations[Rails.env] = @config
  end

  context "password not required in database config" do
    before do
      ActiveRecord::Base.configurations[Rails.env].merge!({"password" => nil })
      allow(File).to receive(:exists?)
      allow(File).to receive(:exists?).with(File.expand_path("~/.pgpass")).and_return(false)
    end

    it "should not raise an exception" do
      expect{ ApplicationDatabase.new.contents }.not_to raise_exception
    end
  end

  context "password is required in database config" do
    before do
      ActiveRecord::Base.configurations[Rails.env].merge!({"password" => "sekret"})
      allow(File).to receive(:exists?)
      allow(File).to receive(:exists?).with(File.expand_path("~/.pgpass")).and_return(false)
    end

    it "should be nil" do
      expect( ApplicationDatabase.new.contents ).to be_nil
    end
  end

  context "password is required in database config and .pgpass file is present" do
    before do
      ActiveRecord::Base.configurations[Rails.env].merge!({"password" => "sekret"})
      allow(File).to receive(:exists?)
      allow(File).to receive(:exists?).with(File.expand_path("~/.pgpass")).and_return(true)
      status = Struct.new(:mode).new(33152) # octal: 100600
      allow(File).to receive(:stat)
      allow(File).to receive(:stat).with(File.expand_path("~/.pgpass")).and_return(status)
    end

    it "should not raise an exception" do
      expect{ ApplicationDatabase.new.contents }.not_to raise_exception
    end
  end

  context "pgpass file has incorrect permissions" do
    before do
      ActiveRecord::Base.configurations[Rails.env].merge!({"password" => "sekret"})
      allow(File).to receive(:exists?)
      allow(File).to receive(:exists?).with(File.expand_path("~/.pgpass")).and_return(true)
      status = Struct.new(:mode).new(33204) # octal: 100664
      allow(File).to receive(:stat)
      allow(File).to receive(:stat).with(File.expand_path("~/.pgpass")).and_return(status)
    end

    it "should be nil" do
      expect(ApplicationDatabase.new.contents).to be_nil
    end
  end

end

describe "PostgresAdapter#create_object_restoral_list_omitting_exclusions" do
  include HttpMockHelpers
  include AwsHelper

  before do
    @archive = GlacierDbArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    create_compressed_archive(@archive)
    change_database
    db_config = ActiveRecord::Base.configurations["test"]
    postgres_adapter = ApplicationDatabase::PostgresAdapter.new(db_config)
    postgres_adapter.send(:generate_object_restoral_list, @archive.backup_file)
  end

  it "should create intermediate file with list of objects to be restored" do
    expect(File.exists?(ApplicationDatabase::PostgresAdapter::RestoreList)).to eq true
    ApplicationDatabase::PostgresAdapter::RestoreExclusions.each do |table|
      expect(File.read(ApplicationDatabase::PostgresAdapter::RestoreList)).not_to match /#{table}/
    end
  end

end

describe "PostgresAdapter#restore_from_list" do
  include HttpMockHelpers
  include AwsHelper

  before do
    @archive = GlacierDbArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    GlacierDbArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    create_compressed_archive(@archive)
    change_database
    db_config = ActiveRecord::Base.configurations["test"]
    postgres_adapter = ApplicationDatabase::PostgresAdapter.new(db_config)
    postgres_adapter.send(:generate_object_restoral_list, @archive.backup_file)
    postgres_adapter.send(:restore_from_list, @archive.backup_file)
  end

  it "should create intermediate file with list of objects to be restored" do
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
    expect(GlacierDbArchive.count).to eq 2
  end

end
