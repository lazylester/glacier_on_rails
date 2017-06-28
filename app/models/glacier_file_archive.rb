require 'get_back/config'

class GlacierFileArchive < GlacierArchive
  has_and_belongs_to_many :application_data_backups, join_table: 'application_data_backups_glacier_file_archives'

  def file=(file)
    self.filename = File.basename(file)
  end

  def file
    GetBack::Config.attached_files_directory.join(filename)
  end

  def initiate_retrieve_job
    # don't retrieve the file if it's in the filesystem already
    # based on the assumption that files are immutable
    super unless File.exists?(file)
  end

  # the bang method creates the instances if they didn't already exist
  def self.all!
    in_filesystem.collect do |file|
      find_or_create_by(:filename => file)
    end
  end

  def archive_contents
    ApplicationFile.new(file).contents
  end

  def exists_status?
    File.exists? file
  end

  def restore
    FileUtils.mv(backup_file, file)
  rescue Errno::ENOENT # usually b/c backup_file not found
    raise RestoreFail
  end

  private
  def self.in_filesystem
    ApplicationFile.list
  end
end
