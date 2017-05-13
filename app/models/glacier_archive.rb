class GlacierArchive < ActiveRecord::Base
  scope :with_pending_retrieval, ->{ where("archive_retrieval_job_id is not null") }
  default_scope ->{ order("created_at asc") }

  def retrieval_status
    return 'ready' if notification
    return 'pending' if archive_retrieval_job_id
    'available'
  end
end
