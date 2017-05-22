class GetBack::AwsArchiveRetrievalJobsController < ApplicationController
  def create
    archive = GlacierArchive.find(params[:archive_id])
    archive.initiate_retrieve_job
    @glacier_archives = GlacierArchive.all
    render :partial => 'glacier_archive', :collection => @glacier_archives, :as => :archive
  end
end
