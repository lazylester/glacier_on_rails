require 'spec_helper'

describe '.list' do
  include DummyAppDb
  it "should list filenames" do
    expect(ApplicationFile.list).to match_array ['1234abc', '4567def', '8899bin']
  end
end
