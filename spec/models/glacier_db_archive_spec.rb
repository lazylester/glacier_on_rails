require 'spec_helper'
# helpers are all required in spec helper


describe 'GlacierDbArchive.create' do
  include HttpMockHelpers
  include AwsHelper

  before do
    @archive = GlacierDbArchive.create
  end

  it 'should create instance of GlacierDbArchive in the database' do
    expect(upload_archive_post).to have_been_requested.once

    expect(@archive.archive_id).not_to be_nil
    expect(@archive.checksum).not_to be_nil
    expect(@archive.location).not_to be_nil
    expect(@archive.retrieval_status).to eq 'available'
  end
end

describe 'GlacierDbArchive.create with error' do
  include HttpMockHelpers
  include AwsHelper

  before do
    upload_archive_post_with_error_response
    @archive = GlacierDbArchive.create
  end

  it 'should not create instance of GlacierDbArchive in the database' do
    expect(upload_archive_post_with_error_response).to have_been_requested.once
    expect(aws_log).to match /Failed to create archive with: Aws::Glacier::Errors::InvalidParameterValueException: Invalid Content-Length: 0/

    expect(@archive.id).to be_nil
    expect(@archive.errors.full_messages[0]).to eq "Failed to create archive with: Aws::Glacier::Errors::InvalidParameterValueException: Invalid Content-Length: 0"
  end
end

describe GlacierOnRails::AwsSnsSubscriptionsController, :type => :controller do
  include HttpMockHelpers
  include AwsHelper

  routes { GlacierOnRails::Engine.routes }

  before do
    @archive = GlacierDbArchive.create
  end

  it "should send archive retrieval job initiation request" do
    expect(@archive.reload.retrieval_status).to eq 'available'
    @archive.initiate_retrieve_job
    expect(initiate_retrieve_job).to have_been_requested.once
    expect(@archive.retrieval_status).to eq 'pending'
  end

  it "should change status to ready when notification is received" do
    @archive.initiate_retrieve_job
    expect(@archive.retrieval_status).to eq 'pending'
    receive_notification
    expect(@archive.reload.retrieval_status).to eq 'ready'
  end

end

describe GlacierOnRails::ApplicationDataBackupsController, :type => :controller do
  include HttpMockHelpers
  include AwsHelper
  routes { GlacierOnRails::Engine.routes }

  context "when archive retrieval job is fresh" do
    before do
      @archive = GlacierDbArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    end

    it "should retrieve the archive" do
      expect(@archive.fetch_archive).to eq true
      expect(@archive.notification).to be_nil
      expect(@archive.archive_retrieval_job_id).to be_nil
      expect(@archive.retrieval_status).to eq 'local'
    end
  end

  context "when archive retrieval job has expired" do
    before do
      fetch_expired_archive # set up the webmock stub
      @archive = GlacierDbArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "expiredJobId")
    end

    it "should return to available status" do
      expect(@archive.fetch_archive).to eq false
      expect(fetch_expired_archive).to have_been_requested.once
      expect(aws_log).to match /Fetch archive failed with: Aws::Glacier::Errors::ResourceNotFoundException: The job ID was not found/
      expect(@archive.notification).to be_nil
      expect(@archive.archive_retrieval_job_id).to be_nil
      expect(@archive.retrieval_status).to eq 'available'
    end
  end

end

describe "GlacierDbArchive#restore" do
  include HttpMockHelpers
  include AwsHelper

  before do
    @archive = GlacierDbArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    create_compressed_archive(@archive)
    change_database
    @archive.restore
  end

  it "should restore the database" do
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
  end

end
