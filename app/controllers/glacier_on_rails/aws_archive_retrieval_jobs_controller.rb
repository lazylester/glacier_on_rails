class GlacierOnRails::AwsArchiveRetrievalJobsController < ApplicationController
  def create
    @application_data_backup = ApplicationDataBackup.find(params[:application_data_backup_id])
    @application_data_backup.initiate_retrieval
    render :partial => 'application_data_backup', :locals => {:application_data_backup => @application_data_backup}
  end
end
