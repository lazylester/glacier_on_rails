require 'spec_helper'

describe "ApplicationDataBackup#create" do
  include HttpMockHelpers
  include DummyAppDb
  before do
    @backup = ApplicationDataBackup.create
  end

  it "should have a single GlacierDbArchive association" do
    expect(@backup.glacier_db_archive).to be_a GlacierDbArchive
  end

  it "should have a GlacierFileArchive for each file attachment" do
    expect(@backup.glacier_file_archives.length).to eq 3 # DummyAppDb creates 3 files
  end

  it "should create exactly one ApplicationDataBackup instance" do
    expect(ApplicationDataBackup.count).to eq 1
  end

  it "should create exactly one GlacierDbArchive" do
    expect(GlacierDbArchive.count).to eq 1
  end
end

describe "ApplicationDataBackup#initiate_retrieval" do
  include HttpMockHelpers
  include DummyAppDb
  include AwsHelper
  context "all aws responses are normal" do
    before do
      create_application_data_backup_with_available_components
      FileUtils.rm(FakeModel::FilePath.join(FakeModel.first.file_id))
      @application_data_backup.initiate_retrieval
    end

    it "should initiate retrieval for database and file archives" do
      expect(@application_data_backup.glacier_db_archive.retrieval_status).to eq 'pending'
      expect(@application_data_backup.glacier_file_archives[0].retrieval_status).to eq 'pending' # b/c its file was removed
      expect(@application_data_backup.glacier_file_archives[1].retrieval_status).to eq 'exists'
      expect(@application_data_backup.glacier_file_archives[2].retrieval_status).to eq 'exists'
      expect(@application_data_backup.retrieval_status).to eq 'pending'
      expect(initiate_retrieve_job).to have_been_requested.times(2) # one pending file and the db
    end
  end

  context "one of the responses has an error" do
    before do
      stub_errored_response_for_initiate_retrieval
      create_application_data_backup_with_available_components
      FileUtils.rm(Dir.glob(FakeModel::FilePath.join('*')))
      @application_data_backup.initiate_retrieval
    end

    it "does not change to pending status if one of the components returns error for the initiate" do
      expect(@application_data_backup.glacier_db_archive.retrieval_status).to eq 'pending' # success response
      expect(@application_data_backup.glacier_file_archives[0].retrieval_status).to eq 'pending' # success response
      expect(@application_data_backup.glacier_file_archives[1].retrieval_status).to eq 'pending' # success response
      expect(@application_data_backup.glacier_file_archives[2].retrieval_status).to eq 'available' # fail response
      expect(@application_data_backup.glacier_file_archives[2].errors.full_messages.first).to eq 'Failed to initiate archive retrieval with: Aws::Glacier::Errors::BadRequest: '
      expect(@application_data_backup.errors.full_messages.first).to eq 'Failed to initiate archive retrieval with: Aws::Glacier::Errors::BadRequest: '
      expect(@application_data_backup.retrieval_status).to eq 'available'
      expect(aws_log).to match /Failed to initiate archive retrieval with: Aws::Glacier::Errors::BadRequest:/
    end
  end
end

describe "ApplicationDataBackup#fetch" do
  include HttpMockHelpers
  include DummyAppDb
  include AwsHelper
  context "when retrieval job ids are current" do
    before do
      create_application_data_backup_with_ready_components
      FakeModel.destroy_all
      @application_data_backup.fetch_archive
    end

    it "should report aggregate status" do
      expect(fetch_db_archive_retrieval_job_output).to have_been_requested.once
      expect(fetch_file_archive_retrieval_job_output).to have_been_requested.times(3)
      expect(@application_data_backup.retrieval_status).to eq "local"
      expect(File.exists?(@application_data_backup.glacier_db_archive.backup_file)).to eq true
      expect(File.exists?(@application_data_backup.glacier_file_archives[0].backup_file)).to eq true
      expect(File.exists?(@application_data_backup.glacier_file_archives[1].backup_file)).to eq true
      expect(File.exists?(@application_data_backup.glacier_file_archives[2].backup_file)).to eq true
    end
  end

  context "when some retrieval job id has expired" do
    before do
      create_application_data_backup_with_ready_components
      FakeModel.destroy_all
      GlacierFileArchive.where(:filename => '1234abc').first.update_attributes(:archive_retrieval_job_id => 'expiredJobId')
      fetch_expired_archive #setup response for expired job
      @application_data_backup = ApplicationDataBackup.first
      @application_data_backup.fetch_archive
    end

    it "does not change to local status if one of the component fetches fails with errors" do
      expect(fetch_db_archive_retrieval_job_output).to have_been_requested.once
      expect(fetch_file_archive_retrieval_job_output).to have_been_requested.times(2)
      expect(fetch_expired_archive).to have_been_requested.once
      expect(@application_data_backup.retrieval_status).to eq "available"
      expect(File.exists?(@application_data_backup.glacier_db_archive.backup_file)).to eq true
      expect(File.exists?(@application_data_backup.glacier_file_archives.find{|a| a.filename=="1234abc"}.backup_file)).to eq false
      expect(File.exists?(@application_data_backup.glacier_file_archives.find{|a| a.filename=="4567def"}.backup_file)).to eq true
      expect(File.exists?(@application_data_backup.glacier_file_archives.find{|a| a.filename=="8899bin"}.backup_file)).to eq true
    end
  end
end

describe "ApplicationDataBackup#restore" do
  include DummyAppDb
  include HttpMockHelpers
  include AwsHelper
  before do
    create_application_data_backup_with_local_components
    @application_data_backup = ApplicationDataBackup.first
    @application_data_backup.glacier_db_archive.reload # not sure why!
    FakeModel.destroy_all
    8.times do |i|
      FakeModel.create(:file_id => "abracadabra#{i}")
    end
    create_application_data_backup_with_local_components
    @application_data_backup.restore
  end

  it "should restore database and each fetched file archive" do
    expect(FakeModel.count).to eq 3
    expect(Dir.glob(GlacierOnRails::Config.attached_files_directory.join('*')).length).to eq 3
    expect(@application_data_backup.retrieval_status).to eq "available"
  end

  it "should move into the orphan_files_directory any files added since the application_data_backup being restored" do
    expect(Dir.glob(GlacierOnRails::Config.orphan_files_directory.join('*')).length).to eq 8
  end

  it "should delete the fetched backup files" do
    expect(Dir.glob( GlacierArchive::BackupFileDir.join('*')).length).to eq 9 # it leaves in place the files that were not restored
  end

  it "should retain and not overwrite application_data_backups table" do
    expect(ApplicationDataBackup.count).to eq 2
  end

  it "should retain and not overwrite glacier_archives table" do
    expect(GlacierDbArchive.count).to eq 2
    expect(GlacierFileArchive.count).to eq 11
  end
end

describe '#pick_lowest' do
  before do
    @app_db = ApplicationDataBackup.new
  end

  it "should pick the lowest status according as the earliest in the archive lifecycle" do
    # just try some random combinations!
    expect(@app_db.send(:pick_lowest, ["ready", "available", "local"])).to eq "available"
    expect(@app_db.send(:pick_lowest, ["local", "ready", "available"])).to eq "available"
    expect(@app_db.send(:pick_lowest, ["exists", "exists", "local"])).to eq "local"
    expect(@app_db.send(:pick_lowest, ["pending", "exists", "ready"])).to eq "pending"
    expect(@app_db.send(:pick_lowest, ["pending", "available", "ready"])).to eq "available"
  end
end

describe '#retrieval_status' do
  context "components have identical retrieval_status" do
    before do
      @application_data_backup = ApplicationDataBackup.new
      allow_any_instance_of(GlacierFileArchive).to receive(:retrieval_status).and_return('pending')
      allow_any_instance_of(GlacierDbArchive).to receive(:retrieval_status).and_return('pending')
      allow(@application_data_backup).to receive(:glacier_file_archives).and_return([GlacierFileArchive.new(:filename => 'abc123')])
      allow(@application_data_backup).to receive(:glacier_db_archive).and_return(GlacierDbArchive.new(:filename => GlacierDbArchive.filename_from_time))
    end

    it "should return pending for application_data_backup#retrieval_status" do
      expect(@application_data_backup.retrieval_status).to eq 'pending'
    end
  end

  context "components have disparate retrieval_status" do
    before do
      @application_data_backup = ApplicationDataBackup.new
      allow_any_instance_of(GlacierFileArchive).to receive(:retrieval_status).and_return('pending')
      allow_any_instance_of(GlacierDbArchive).to receive(:retrieval_status).and_return('ready')
      allow(@application_data_backup).to receive(:glacier_file_archives).and_return([GlacierFileArchive.new(:filename => 'abc123')])
      allow(@application_data_backup).to receive(:glacier_db_archive).and_return(GlacierDbArchive.new(:filename => GlacierDbArchive.filename_from_time))
    end

    it "should return pending for application_data_backup#retrieval_status" do
      expect(@application_data_backup.retrieval_status).to eq 'pending'
    end
  end
end

describe '#destroy' do
  include HttpMockHelpers
  include DummyAppDb
  include AwsHelper

  context "glacier_file_archives do not belong to any other application_data_backups" do
    before do
      create_application_data_backup_with_ready_components
    end

    it "should destroy all associated archives" do
      expect{@application_data_backup.destroy}.to change{ GlacierDbArchive.count }.from(1).to(0).
                                               and change{ GlacierFileArchive.count }.from(3).to(0)
    end
  end

  context "glacier_file_archives also belong to other application_data_backups" do
    before do
      create_application_data_backup_with_ready_components
      create_application_data_backup_with_ready_components
    end

    it "should not destroy associated archives that also belong to another application_data_backup" do
      expect{@application_data_backup.destroy}.to change{ GlacierDbArchive.count }.from(2).to(1)
      expect( GlacierFileArchive.count ).to eq 3
    end
  end
end
