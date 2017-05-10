class GlacierArchive < ActiveRecord::Base
  scope :with_pending_retrieval, ->{ where("archive_retrieval_job_id is not null") }
end
