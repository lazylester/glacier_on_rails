# GlacierArchive lifecycle:
# ACTION                    | IMPLEMENTED BY                | PARAMETER                | STATUS INDICATION             | STATUS
# create                    | AwsBackend#create_archive     |                          | default attributes            | available
# initiate retrieval job    | AwsBackend#retrieve_archive   | archive_id               | archive_retrieval_job_id      | pending
# SNS notification received | AwsSnsSubscriptionsController | archive_retrieval_job_id | notification attribute        | ready
# fetch archive             | AwsArchiveController#fetch    | archive_retrieval_job_id | retrieved file exists locally | local
#                           |                               |                          | original file exists locally  | exists
class GlacierArchive < ActiveRecord::Base
  class RestoreFail < StandardError; end

  default_scope ->{ order("created_at asc") }

  BackupFileDir = Rails.root.join('tmp','aws')

  before_create do |archive|
    # create the archive at AWS Glacier
    # and save the metadata in the GlacierArchive instance
    # archive_contents provided by subclass (GlacierDbArchive or GlacierFileArchive)
    if archive_contents && (resp = aws.create_archive(archive_contents))
      archive.attributes = resp.to_h
    else
      archive.errors.add(:base, aws.error_message)
      throw :abort
    end
  end

  after_destroy do |archive|
    archive.remove_local_backup_copy
  end

  before_destroy do |archive|
    archive.destroy_archive
  end

  def destroy_archive
    begin
      response = aws.delete_archive(self)
      AwsLog.info(response)
      true
    rescue Aws::Glacier::Errors::ServiceError => e
      AwsLog.error("Delete archived failed with :#{e.class}: #{e.message}")
      false
    end
  end

  def initiate_retrieve_job
    if resp = aws.retrieve_archive(self)
      update_attribute(:archive_retrieval_job_id, resp[:job_id])
    else
      errors.add(:base, aws.error_message)
    end
  end

  def fetch_archive
    begin
      response = aws.get_job_output(self)
      AwsLog.info(response.to_h) if response
      true
    rescue Aws::Glacier::Errors::ServiceError => e
      self.errors.add(:base, e.message)
      AwsLog.error("Fetch archive failed with: #{e.class}: #{e.message}")
      false
    ensure
      reset_retrieval_status
    end
  end

  def retrieval_status
    exists_status || local_status || ready_status || pending_status || 'available'
  end

  def backup_file
    BackupFileDir.join(filename)
  end

  protected

  def remove_local_backup_copy
    FileUtils.rm(backup_file) if local_status?
  end

  private

  def aws
    AwsBackend.instance
  end

  def reset_retrieval_status
    # because error messages will be reset when update_attributes is used
    update_columns(:archive_retrieval_job_id => nil, :notification => nil)
  end

  def exists_status
    'exists' if exists_status?
  end

  def local_status?
    File.exists? backup_file
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
