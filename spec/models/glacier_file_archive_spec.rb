require 'spec_helper'

describe 'GlacierFileArchive.all!' do
  include HttpMockHelpers
  include AwsHelper
  include DummyAppDb
  before do
    GlacierFileArchive.all!
  end

  it "should create an archive for each file attachment" do
    # just verifying FakeModel here!
    expect(File.exists?(FakeModel::FilePath.join('1234abc'))).to eq true
    expect(File.exists?(FakeModel::FilePath.join('4567def'))).to eq true
    expect(File.exists?(FakeModel::FilePath.join('8899bin'))).to eq true
    expect(GlacierFileArchive.pluck(:filename)).to match_array ['1234abc', '4567def', '8899bin']
  end

  it "should add new files" do
    FakeModel.create(:file_id => '6666zyx')
    expect(GlacierFileArchive.pluck(:filename)).to match_array ['1234abc', '4567def', '8899bin']
    GlacierFileArchive.all!
    expect(GlacierFileArchive.pluck(:filename)).to match_array ['1234abc', '4567def', '8899bin', '6666zyx']
  end

end

describe '#initiate_retrieve_job' do
  include HttpMockHelpers
  context "when file does not exist in the filesystem" do
    before do
      FakeModel.create(:file_id => '6666zyx')
      @archive = GlacierFileArchive.create(:filename => '6666zyx')
      FileUtils.rm(FakeModel::FilePath.join('6666zyx'))
      @archive.initiate_retrieve_job
    end

    it "should send a job initiation request and change status to pending" do
      expect(initiate_retrieve_job).to have_been_requested.once
      expect(@archive.retrieval_status).to eq 'pending'
    end
  end

  context "when file exists in the filesystem" do
    before do
      FakeModel.create(:file_id => '6666zyx')
      @archive = GlacierFileArchive.create(:filename => '6666zyx')
      @archive.initiate_retrieve_job
    end

    it "should not send a job initiation request and should change status to exists" do
      expect(initiate_retrieve_job).not_to have_been_requested
      expect(@archive.retrieval_status).to eq 'exists'
    end
  end
end
