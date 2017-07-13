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

  context "when restoral is successful" do
    it "should restore the database" do
      page.find('.restore_database').click
      wait_for_ajax
      expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
      expect(flash_message).to eq "Database restored with the #{@application_data_backup.created_at.to_date.to_s} backup"
      expect(page).to have_selector('td#initiate_retrieval')
    end
  end

  context "when restoral fails" do
    before do
      allow_any_instance_of(ApplicationDatabase).to receive(:restore).and_return(false)
    end

    it "should restore the database" do
      page.find('.restore_database').click
      wait_for_ajax
      expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bosh' # b/c restore failed
      expect(flash_message).to eq "Database restore failed"
      expect(page).to have_selector('td.restore_database')
    end
  end
end

feature "backup_now", :js => true do
  include HttpMockHelpers
  include AwsHelper
  include DummyAppDb

  before do
    visit admin_path
  end

  context "when no errors are generated by AWS Glacier" do
    it "should create a new application_data_backup" do
      expect{page.find('#backup_now').click; wait_for_ajax}.to change{ApplicationDataBackup.count}.from(0).to(1)
      expect( upload_archive_post ).to have_been_requested.times(4)
      expect(page).to have_selector("#application_data_backups .application_data_backup", :count => 1)
    end
  end

  context "when AWS responds with an error" do
    before do
      upload_archive_post_with_error_response
      # mock the errored response
      # Failed to create archive with: Aws::Glacier::Errors::InvalidParameterValueException: Invalid Content-Length: 0
    end

    it "should not create a new application_data_backup" do
      expect{page.find('#backup_now').click; wait_for_ajax}.not_to change{ApplicationDataBackup.count}
      expect( upload_archive_post_with_error_response ).to have_been_requested.times(1)
      expect(page).not_to have_selector("#application_data_backups .application_data_backup")
      expect(flash_message).to eq "failed to create backup"
    end
  end

  context "when AWS sdk responds with an error" do
    before do
      allow_any_instance_of(Aws::Plugins::RequestSigner::Handler).to receive(:missing_credentials?).and_return(true)
    end

    it "should not create a new application_data_backup" do
      page.find('#backup_now').click
      wait_for_ajax
      expect(flash_message).to eq "failed to create backup"
    end
  end

  context "when there is a database configuration error" do
    before do
      allow(ActiveRecord::Base).to receive(:configurations).and_return({"test"=> {"host" => "bosh"}})
    end

    it "should not create a new application_data_backup" do
      expect{page.find('#backup_now').click; wait_for_ajax}.not_to change{ApplicationDataBackup.count}
      expect( upload_archive_post_with_error_response ).not_to have_been_requested
      expect(page).not_to have_selector("#application_data_backups .application_data_backup")
      expect(flash_message).to eq "failed to create backup"
    end
  end

  context "when there is a missing database password file" do
    before do
      @config = ActiveRecord::Base.configurations[Rails.env].dup
      ActiveRecord::Base.configurations[Rails.env].merge!({"password" => "sekret"})
      allow(File).to receive(:exists?)
      allow(File).to receive(:exists?).with("~/.pgpass").and_return(false)
    end

    after do
      ActiveRecord::Base.configurations[Rails.env] = @config
    end

    it "should not create a new application_data_backup" do
      expect{page.find('#backup_now').click; wait_for_ajax}.not_to change{ApplicationDataBackup.count}
      expect(page).not_to have_selector("#application_data_backups .application_data_backup")
      expect(flash_message).to eq "failed to create backup"
      expect(aws_log).to match /ApplicationDatabase::PostgresAdapter::PgPassFileMissing exception: #{File.expand_path("~/.pgpass")} file not found, cannot dump database contents/
    end
  end
end
