class GetBack::AwsArchivesController < ApplicationController
  def fetch
    @archive = GlacierArchive.find(params[:archive_id])
    @archive.fetch_archive if @archive
    render :partial => 'glacier_archive', :collection => GlacierArchive.all, :as => :archive
  end

  def restore
    @archive = GlacierArchive.find(params[:archive_id])
    if @archive.restore
      render :js => "flash.set('confirm_message', 'database restored to #{@archive.created_at.to_date.to_s(:default)}');flash.notify();"
    else
      render :js => "flash.set('error_message', 'database restore failed');flash.notify();"
    end
  end
end
