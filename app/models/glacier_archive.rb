# GlacierArchive lifecycle:
# when an instance is created, AwsBackend#create_db_archive is invoked, status is 'available'
# when an instance initiates a retrieval job, AwsBackend#retrieve_db_archive is invoked, status becomes 'pending'
# when AWS SNS notification is received (aws_sns_subscriptions_controller), status becomes 'ready'
# when fetch_archive is invoked by user, AwsArchiveController#fetch is invoked, and backup file is saved locally, status becomes 'local'
class GlacierArchive < ActiveRecord::Base
  default_scope ->{ order("created_at asc") }

  LocalFileDir = Rails.root.join('tmp','aws')

  before_create do |archive|
    # create the archive at AWS Glacier
    # and save the metadata in the GlacierArchive instance
    if resp = aws.create_db_archive
      archive.attributes = resp.to_h
    end
  end

  after_destroy do |archive|
    FileUtils.rm(archive.local_filepath) if archive.local_status?
  end

  def aws
    AwsBackend.new
  end

  def initiate_retrieve_job
    if resp = aws.retrieve_db_archive(self)
      update_attribute(:archive_retrieval_job_id, resp[:job_id])
    end
  end

  def fetch_archive
    aws.get_job_output(self)
  end

  def restore
    ApplicationDatabase.new.restore(local_filepath)
  end

  def retrieval_status
    local_status || ready_status || pending_status || 'available'
  end

  def local_filepath
    LocalFileDir.join(local_filename).to_s
  end

  def local_status?
    File.exists? local_filepath
  end

  private

  def local_filename
    created_at.strftime("%Y_%m_%d_%H_%M_%S.sql")
  end

  # archive_retrieval job output has been retrieved
  def local_status
    'local' if local_status?
  end

  # ready to retrieve archive_retrieve job output
  def ready_status
    'ready' if notification
  end

  # archive_retrieve job has been initiated, but notification not yet received
  def pending_status
    'pending' if archive_retrieval_job_id
  end
end
