require 'spec_helper'

describe 'GlacierFileArchive.all' do
  include HttpMockHelpers
  include AwsHelper
  before do
    FakeModel.create(:file_id => '123abc')
    FakeModel.create(:file_id => '456xyz')
  end

  it "should create new models if they didn't already exist" do
    expect{ GlacierFileArchive.update_archive }.to change{ GlacierFileArchive.count }.from(0).to(2)
    expect(get_vault_list_request).to have_been_requested.twice
    expect(create_vault_request).to have_been_requested.twice
    expect(upload_archive_post).to have_been_requested.twice

    glacier_archive = GlacierFileArchive.first
    expect(glacier_archive.archive_id).not_to be_nil
    expect(glacier_archive.checksum).not_to be_nil
    expect(glacier_archive.location).not_to be_nil
    expect(glacier_archive.retrieval_status).to eq 'available'
  end

  it "should include already-existing models" do

  end
end

describe 'GlacierFileArchive.update_archive' do
  include HttpMockHelpers
  include AwsHelper
  include DummyAppDb
  before do
    GlacierFileArchive.update_archive
  end

  # just verifying FakeModel here!
  it "should have files in the attached files directory" do
    expect(GlacierFileArchive.pluck(:filename)).to match_array ['1234abc', '4567def', '8899bin']
    expect(File.exists?(FakeModel::FilePath.join('1234abc'))).to eq true
    expect(File.exists?(FakeModel::FilePath.join('4567def'))).to eq true
    expect(File.exists?(FakeModel::FilePath.join('8899bin'))).to eq true
  end

  it "should create an archive for each file attachment" do
    expect(GlacierFileArchive.count).to eq 3
    expect(GlacierFileArchive.archived).to match_array ['1234abc', '4567def', '8899bin']
  end
end
