class GetBack::ApplicationDataBackupsController < ApplicationController
  before_action do
    @application_data_backup = ApplicationDataBackup.find(params[:application_data_backup_id]) unless params[:application_data_backup_id].nil?
  end

  def create
    if @application_data_backup = ApplicationDataBackup.create
      render :partial => 'get_back/aws_archive_retrieval_jobs/application_data_backup', :locals => {:application_data_backup => @application_data_backup}
    end
  end

  def fetch
    if @application_data_backup.fetch_archive
      render :partial => 'get_back/aws_archive_retrieval_jobs/application_data_backup',
             :locals => {:application_data_backup => @application_data_backup}
    else
      render :partial => 'get_back/aws_archive_retrieval_jobs/application_data_backup',
             :locals => {:application_data_backup => @application_data_backup, :fetch_fail => true}
    end
  end

  def restore
    if @application_data_backup.restore
      render :js => "flash.confirm('Database restored with the #{@application_data_backup.created_at.to_date.to_s(:default)} backup');"
    else
      render :js => "flash.error('database restore failed');"
    end
  end

  def destroy
    if @application_data_backup.destroy
      head :ok
    else
      render :js => "flash.error('Deletion of archive failed for some reason');", :status => 500
    end
  end

end
