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

  def self.get_all
    update_archive
    all
  end

  def self.update_archive
    (in_filesystem - archived).each do |file|
      create(:file => file)
    end
  end

  def archive_contents
    ApplicationFile.new(file).contents
  end

  private
  def self.in_filesystem
    ApplicationFile.files
  end

  def self.archived
    pluck(:filename)
  end
end
