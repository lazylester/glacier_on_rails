require 'spec_helper'

describe "ApplicationDataBackup#create_archive" do
  include HttpMockHelpers
  include DummyAppDb
  before do
    @backup = ApplicationDataBackup.new
    @backup.create_archive
  end

  it "should have a single GlacierDbArchive association" do
    expect(@backup.glacier_db_archive).to be_a GlacierDbArchive
  end

  it "should have a GlacierFileArchive for each file attachment" do
    expect(@backup.glacier_file_archives.length).to eq 3 # DummyAppDb creates 3 files
  end
end
