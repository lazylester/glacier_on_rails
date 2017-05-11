class GlacierArchive < ActiveRecord::Base
  scope :with_pending_retrieval, ->{ where("archive_retrieval_job_id is not null") }
  default_scope ->{ order("created_at asc") }

  def retrieval_status
    if archive_retrieval_job_id
      'retrieval pending'
    elsif notification
      'retrieval ready'
    end
  end
end
