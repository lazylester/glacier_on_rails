require 'spec_helper'
# helpers are all required in spec helper

describe "PostgresAdapter#create_object_restoral_list_omitting_exclusions" do
  include HttpMockHelpers
  include AwsHelper

  before do
    @archive = GlacierDbArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    create_compressed_archive(@archive)
    change_database
    db_config = ActiveRecord::Base.configurations["test"]
    postgres_adapter = ApplicationDatabase::PostgresAdapter.new(db_config)
    postgres_adapter.send(:object_restoral_list, @archive.backup_file)
  end

  it "should create intermediate file with list of objects to be restored" do
    restore_list = GlacierArchive::BackupFileDir.join('restore.list')
    expect(File.exists?(restore_list)).to eq true
    ApplicationDatabase::PostgresAdapter::RestoreExclusions.each do |table|
      expect(File.read(restore_list)).not_to match /#{table}/
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
    list = postgres_adapter.send(:object_restoral_list, @archive.backup_file)
    postgres_adapter.send(:restore_from_list, @archive.backup_file)
  end

  it "should create intermediate file with list of objects to be restored" do
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
    expect(GlacierDbArchive.count).to eq 2
  end

end
