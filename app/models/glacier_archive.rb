# GlacierArchive lifecycle:
# ACTION                    | IMPLEMENTED BY                 | PARAMETER                | STATUS INDICATION             | STATUS
# create                    | AwsBackend#create_archive   |                          | default attributes            | available
# initiate retrieval job    | AwsBackend#retrieve_archive | archive_id               | archive_retrieval_job_id      | pending
# SNS notification received | AwsSnsSubscriptionsController  | archive_retrieval_job_id | notification attribute        | ready
# fetch archive             | AwsArchiveController#fetch     | archive_retrieval_job_id | retrieved file exists locally | local
#
class GlacierArchive < ActiveRecord::Base
  default_scope ->{ order("created_at asc") }

  LocalFileDir = Rails.root.join('tmp','aws')

  before_create do |archive|
    # create the archive at AWS Glacier
    # and save the metadata in the GlacierArchive instance
    # archive_contents provided by subclass (GlacierDbArchive or GlacierFileArchive)
    if resp = aws.create_archive(archive_contents)
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
    end
  end

  def fetch_archive
    begin
      response = aws.get_job_output(self)
      AwsLog.info(response.to_h) if response
      true
    rescue Aws::Glacier::Errors::ServiceError => e
      AwsLog.error("Fetch archive failed with: #{e.class}: #{e.message}")
      false
    ensure
      reset_retrieval_status
    end
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

  protected

  def remove_local_backup_copy
    FileUtils.rm(local_filepath) if local_status?
  end

  private

  def aws
    @aws ||= AwsBackend.new
  end

  def reset_retrieval_status
    update_attributes(:archive_retrieval_job_id => nil, :notification => nil)
  end

  def local_status?
    File.exists? local_filepath
  end

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
