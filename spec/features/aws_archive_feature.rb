require 'spec_helper'
require 'rails_helper'
require 'aws_helper'

feature "initiate archive retrieval job", :js => true do
  include AwsHelper

  before do
    @archive = GlacierArchive.create
    visit admin_path
  end

  it "should initiate aws retrieval job and set status to pending" do
    expect{page.find('#initiate_retrieval').click; wait_for_ajax}.to change{ @archive.reload.retrieval_status }.from('available').to('pending')
    expect(initiate_retrieve_job).to have_been_requested.once
    expect(page).to have_selector('#glacier_archives .glacier_archive .retrieval_pending')
  end
end

feature "retrieve archive from aws", :js => true do
  include AwsHelper

  context "retrieval job id has expired" do
    before do
      fetch_expired_archive # sets up the webmock method stub
      @archive = GlacierArchive.create
      @archive.update_attributes(:archive_retrieval_job_id => "expiredJobId", :notification => "bar")
      visit admin_path
    end

    it "should show failure message and reset archive status" do
      expect(page).to have_selector('#fetch_archive')
      page.find('#fetch_archive').click
      wait_for_ajax
      expect(fetch_expired_archive).to have_been_requested.once
      expect(page).to have_selector("#fetch_fail_message", :text => "fail")
    end
  end
end

feature "delete glacier_archive object and aws archive", :js => true do
  include AwsHelper

  before do
    @archive = GlacierArchive.create
    @archive.update_attributes(:archive_id => "myArchiveId")
    visit admin_path
  end

  it "should send archive delete message to aws" do
    page.find('#delete_archive').click
    wait_for_ajax
    expect(delete_archive).to have_been_requested.once
    expect(GlacierArchive.count).to eq 0
    expect(page.all('#glacier_archives .glacier_archive').length).to be 0
  end
end

feature "restore database from retrieved archive", :js => true do
  include AwsHelper

  before do
    @glacier_archive = GlacierArchive.create(:archive_id => 'myArchiveId')
    create_compressed_archive(@glacier_archive)
    delete_database
    visit admin_path
  end

  it "should restore the database" do
    page.find('.restore_database').click
    wait_for_ajax
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
  end
end
