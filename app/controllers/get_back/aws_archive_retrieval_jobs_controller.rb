class GetBack::AwsArchiveRetrievalJobsController < ApplicationController
  def create
    application_data_backup = ApplicationDataBackup.find(params[:application_data_backup_id])
    application_data_backup.initiate_retrieval
    @application_data_backups = ApplicationDataBackup.all
    render :partial => 'application_data_backup', :collection => @application_data_backups, :as => :application_data_backup
  end
end
