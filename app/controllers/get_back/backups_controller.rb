module GetBack
  class BackupsController < ApplicationController
    def index
      @backups = BackupFile.find(:all).sort
    end

    # creates a new backup file from the database
    def create
      backup = BackupFile.new # creates new BackupFile object with current date/time
      backup.save
      redirect_to backups_path
    end

    # restores the selected backup file (denoted by the passed-in param[:id]) to be the active database
    # the passed-in :id field is not the typical numeric table index but instead has the filename root, like:
    # "backups_2009-08-16_07-50-26_development_dump"
    def restore
      backfile = BackupFile.find(params[:id])
      if write_db(backfile)
        flash[:notice] = "Database has been restored to backup version dated:<br/>#{backfile.date}"
      else
        flash[:error] ||= "Restore database failed<br/>file was probably corrupted."
      end
      redirect_to backups_path
    end

    def restore_from_upload
      if params[:upload][:uploaded_file].blank?
        flash[:error] = "Please click \"Browse\" to select a local database file to upload" # this should never be called, as the detection is now done in javascript at the client. Leave it here for posterity!
      else
        backfile = BackupFile.new(:filename=>uploaded_file_path)
        if write_db(backfile)
          flash[:notice] = "Database restored from uploaded file<br/>with date #{backfile.date}"
        else
          flash[:error] ||= "Database restore failed"
        end
      end
      redirect_to backups_path
    end

    def destroy
      backup_file = BackupFile.find(params[:id])
      if backup_file.destroy
        flash[:notice] = "Backup file was deleted"
      else
        flash[:error] = "Delete backup file failed"
      end
      redirect_to backups_path
    end

    # here "show" is used for REST conformance. Here we download the file instead of displaying it
    def show
      backup_file = BackupFile.find(params[:id])
      send_file backup_file.filename
    end

    private

    # overwrites the active database with the file passed in
    def write_db(backfile)
      if backfile.valid?
        ApplicationDatabase.restore_from_file(backfile) # returns false if restore fails
      else
        flash[:error] = "File name does not have correct format.<br/>Are you sure it's a database backup file?<br/>Database was not restored."
        false
      end
    end

    def uploaded_file_path
      # TODO should unzip after uploading
      filename = params[:upload][:uploaded_file].original_filename
      directory = "tmp/uploads"
      path = File.join(directory, filename)
      File.open(path,"wb"){|f| f.write(params[:upload][:uploaded_file].read)}
      #File.join(RAILS_ROOT,path)
      Rails.root.join(path)
    end

  end
end
