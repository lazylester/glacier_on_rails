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
