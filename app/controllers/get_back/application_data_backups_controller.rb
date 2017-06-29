class GetBack::ApplicationDataBackupsController < ApplicationController
  before_action do
    @application_data_backup = ApplicationDataBackup.find(params[:application_data_backup_id]) unless params[:application_data_backup_id].nil?
  end

  def create
    @application_data_backup = ApplicationDataBackup.create
    if @application_data_backup.persisted?
      render :partial => 'get_back/aws_archive_retrieval_jobs/application_data_backup',
             :locals => {:application_data_backup => @application_data_backup}
    else
      render :js => "flash.error('failed to create backup');", :status => 500
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
      render :partial => 'get_back/aws_archive_retrieval_jobs/application_data_backup',
             :locals => {:application_data_backup => @application_data_backup}
    else
      render :js => "flash.error('Database restore failed');", :status => 500
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
