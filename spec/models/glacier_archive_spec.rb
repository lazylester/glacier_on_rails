require 'spec_helper'
require_relative '../helpers/aws_helper'

describe 'GlacierArchive.create' do
  include AwsHelper
  before do
    @glacier_archive = GlacierArchive.create
  end

  it 'should create instance of GlacierArchive in the database' do
    expect(get_vault_list_request).to have_been_requested.once
    expect(create_vault_request).to have_been_requested.once
    expect(upload_archive_post).to have_been_requested.once

    expect(@glacier_archive.archive_id).not_to be_nil
    expect(@glacier_archive.checksum).not_to be_nil
    expect(@glacier_archive.location).not_to be_nil
    expect(@glacier_archive.retrieval_status).to eq 'available'
  end

end

describe GetBack::AwsSnsSubscriptionsController, :type => :controller do
  include AwsHelper

  routes { GetBack::Engine.routes }

  before do
    @glacier_archive = GlacierArchive.create
  end

  it "should send archive retrieval job initiation request" do
    expect(@glacier_archive.reload.retrieval_status).to eq 'available'
    @glacier_archive.initiate_retrieve_job
    expect(initiate_retrieve_job).to have_been_requested.once
    expect(@glacier_archive.retrieval_status).to eq 'pending'
  end

  it "should change status to ready when notification is received" do
    @glacier_archive.initiate_retrieve_job
    expect(@glacier_archive.retrieval_status).to eq 'pending'
    receive_notification
    expect(@glacier_archive.reload.retrieval_status).to eq 'ready'
  end

end

describe GetBack::AwsArchivesController, :type => :controller do
  include AwsHelper
  routes { GetBack::Engine.routes }

  context "when archive retrieval job is fresh" do
    before do
      @glacier_archive = GlacierArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    end

    it "should retrieve the archive" do
      expect(@glacier_archive.fetch_archive).to eq true
      expect(@glacier_archive.notification).to be_nil
      expect(@glacier_archive.archive_retrieval_job_id).to be_nil
      expect(@glacier_archive.retrieval_status).to eq 'local'
    end
  end

  context "when archive retrieval job has expired" do
    before do
      @glacier_archive = GlacierArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "expiredJobId")
      fetch_expired_archive # set up the webmock stub
    end

    it "should return to available status" do
      expect(@glacier_archive.fetch_archive).to eq false
      expect(fetch_expired_archive).to have_been_requested.once
      expect(aws_log).to match /Fetch archive failed with: Aws::Glacier::Errors::ResourceNotFoundException: The job ID was not found/
      expect(@glacier_archive.notification).to be_nil
      expect(@glacier_archive.archive_retrieval_job_id).to be_nil
      expect(@glacier_archive.retrieval_status).to eq 'available'
    end
  end

end

describe "GlacierArchive#restore" do
  include AwsHelper

  before do
    @glacier_archive = GlacierArchive.create(:notification => "got a notification", :archive_retrieval_job_id => "validJobId")
    create_compressed_archive(@glacier_archive)
    delete_database
    @glacier_archive.restore
  end

  it "should restore the database" do
    expect(ActiveRecord::Base.connection.execute("select * from test").first["foo"]).to eq 'bar'
  end

end
