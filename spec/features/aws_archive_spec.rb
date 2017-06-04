require 'spec_helper'
require 'rails_helper'
require 'aws_helper'
require 'http_mock_helpers'

feature "initiate archive retrieval job", :js => true do
  include HttpMockHelpers
  include AwsHelper

  before do
    @archive = GlacierDbArchive.create
    visit admin_path
  end

  it "should initiate aws retrieval job and set status to pending" do
    expect{page.find('#initiate_retrieval').click; wait_for_ajax}.to change{ @archive.reload.retrieval_status }.from('available').to('pending')
    expect(initiate_retrieve_job).to have_been_requested.once
    expect(page).to have_selector('#glacier_archives .glacier_archive .retrieval_pending')
  end
end

feature "retrieve archive from aws", :js => true do
  include HttpMockHelpers
  include AwsHelper

  context "retrieval job id has expired" do
    before do
      fetch_expired_archive # sets up the webmock method stub
      @archive = GlacierDbArchive.create
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

  context "retrieval job still valid" do
    before do
      fetch_archive_retrieval_job_output # sets up the webmock method stub
      @archive = GlacierDbArchive.create
      @archive.update_attributes(:archive_retrieval_job_id => "validJobId", :notification => "bar")
      visit admin_path
    end

    it "should show failure message and reset archive status" do
      expect(page).to have_selector('#fetch_archive')
      page.find('#fetch_archive').click
      wait_for_ajax
      expect(fetch_archive_retrieval_job_output).to have_been_requested.once
      expect(page).to have_selector(".restore_database")
    end
  end

end

feature "delete glacier_archive object and aws archive", :js => true do
  include HttpMockHelpers
  include AwsHelper

  before do
    @archive = GlacierDbArchive.create
    @archive.update_attributes(:archive_id => "myArchiveId")
    visit admin_path
  end

  it "should send archive delete message to aws" do
    page.find('#delete_archive').click
    wait_for_ajax
    expect(delete_archive).to have_been_requested.once
    expect(GlacierDbArchive.count).to eq 0
    expect(page.all('#glacier_archives .glacier_archive').length).to be 0
  end
end

feature "restore database from retrieved archive", :js => true do
  include HttpMockHelpers
  include AwsHelper

  before do
    @glacier_archive = GlacierDbArchive.create(:archive_id => 'myArchiveId')
    create_compressed_archive(@glacier_archive)
    change_database
    visit admin_path
  end

  it "should restore the database" do
    page.find('.restore_database').click
    wait_for_ajax
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
    expect(flash_message).to eq "Database restored with the #{@glacier_archive.created_at.to_date.to_s} backup"
  end
end
