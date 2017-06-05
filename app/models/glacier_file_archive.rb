require 'get_back/config'

class GlacierFileArchive < GlacierArchive
  has_and_belongs_to_many :application_data_backups, join_table: 'application_data_backups_glacier_file_archives'
  attr_accessor :file

  def file=(file)
    self.filename = File.basename(file)
  end

  def file
    GetBack::Config.attached_files_directory.join(filename)
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

  private
  def self.in_filesystem
    ApplicationFile.list
  end
end
