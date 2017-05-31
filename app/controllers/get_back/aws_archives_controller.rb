class GetBack::AwsArchivesController < ApplicationController

  def fetch
    @archive = GlacierArchive.find(params[:archive_id])
    if @archive.fetch_archive
      render :partial => 'get_back/aws_archive_retrieval_jobs/glacier_archive', :locals => {:archive => @archive}
    else
      render :partial => 'get_back/aws_archive_retrieval_jobs/glacier_archive', :locals => {:archive => @archive, :fetch_fail => true}, :status => 410
    end
  end

  def restore
    @archive = GlacierArchive.find(params[:archive_id])
    if @archive.restore
      render :js => "flash.confirm('Database restored with the #{@archive.created_at.to_date.to_s(:default)} backup');"
    else
      render :js => "flash.set('error_message', 'database restore failed');flash.notify();"
    end
  end

  def destroy
    @archive = GlacierArchive.find(params[:archive_id])
    if @archive.destroy
      head :ok
    else
      render :js => "flash.error('Deletion of archive failed for some reason');", :status => 500
    end
  end

end
