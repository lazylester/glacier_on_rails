require 'spec_helper'

feature "initiate application_data_backup retrieval job", :js => true do
  include HttpMockHelpers
  include DummyAppDb
  include AwsHelper

  before do
    create_application_data_backup_with_available_components
    remove_attached_files_from_filesystem
    visit admin_path
  end

  it "should initiate aws retrieval job and set status to pending" do
    expect{page.find('#initiate_retrieval').click; wait_for_ajax}.to change{ @application_data_backup.reload.retrieval_status }.from('available').to('pending')
    expect(initiate_retrieve_job).to have_been_requested.times(4)
    expect(page).to have_selector('#application_data_backups .application_data_backup .retrieval_pending')
  end
end

feature "retrieve application_data_backup from aws", :js => true do
  include HttpMockHelpers
  include DummyAppDb
  include AwsHelper

  context "retrieval job id has expired" do
    before do
      fetch_expired_archive # sets up the webmock method stub
      create_application_data_backup_with_ready_and_expired_components
      remove_attached_files_from_filesystem
      visit admin_path
    end

    it "should show failure message and reset application_data_backup status" do
      expect(page).to have_selector('#fetch_archive')
      page.find('#fetch_archive').click
      wait_for_ajax
      expect(fetch_expired_archive).to have_been_requested.once
      expect(fetch_file_archive_retrieval_job_output).to have_been_requested.times(2)
      expect(fetch_db_archive_retrieval_job_output).to have_been_requested.once
      expect(page).to have_selector("#fetch_fail_message", :text => "fail")
    end
  end

  context "retrieval job still valid" do
    before do
      fetch_file_archive_retrieval_job_output
      fetch_db_archive_retrieval_job_output
      create_application_data_backup_with_ready_components
      remove_attached_files_from_filesystem
      visit admin_path
    end

    it "should show failure message and reset application_data_backup status" do
      expect(page).to have_selector('#fetch_archive')
      page.find('#fetch_archive').click
      wait_for_ajax
      expect(fetch_file_archive_retrieval_job_output).to have_been_requested.times(3)
      expect(fetch_db_archive_retrieval_job_output).to have_been_requested.once
      expect(page).to have_selector(".restore_database")
    end
  end

end

feature "delete application_data_backup object and aws application_data_backup", :js => true do
  include HttpMockHelpers
  include DummyAppDb
  include AwsHelper

  before do
    create_application_data_backup_with_available_components
    visit admin_path
  end

  it "should send application_data_backup delete message to aws" do
    page.find('#delete_archive').click
    wait_for_ajax
    expect(delete_archive).to have_been_requested.times(4)
    expect(ApplicationDataBackup.count).to eq 0
    expect(GlacierArchive.count).to eq 0
    expect(page.all('#application_data_backups .application_data_backup').length).to be 0
  end
end

feature "restore database from retrieved application_data_backup", :js => true do
  include HttpMockHelpers
  include AwsHelper

  before do
    create_application_data_backup_with_local_database_components
    create_compressed_archive(@application_data_backup.glacier_db_archive)
    change_database
    visit admin_path
  end

  it "should restore the database" do
    page.find('.restore_database').click
    wait_for_ajax
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
    expect(flash_message).to eq "Database restored with the #{@application_data_backup.created_at.to_date.to_s} backup"
  end
end

feature "backup_now", :js => true do
  include HttpMockHelpers
  include AwsHelper
  include DummyAppDb

  before do
    visit admin_path
  end

  it "should create a new application_data_backup" do
    expect{page.find('#backup_now').click; wait_for_ajax}.to change{ApplicationDataBackup.count}.from(0).to(1)
    expect( upload_archive_post ).to have_been_requested.times(4)
    expect(page).to have_selector("#application_data_backups .application_data_backup", :count => 1)
  end
end
