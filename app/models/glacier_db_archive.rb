class GlacierDbArchive < GlacierArchive
  belongs_to :application_data_backup

  before_create do |db_archive|
    db_archive.filename = GlacierDbArchive.filename_from_time
  end

  def self.filename_from_time
    Time.now.strftime("%Y_%m_%d_%H_%M_%S_%L.sql").to_s
  end

  def archive_contents
    ApplicationDatabase.new.contents
  end

  # for file archive, true inhibits fetching archive from AWS
  # however we always want to fetch the db archive
  def exists_status?
    false
  end

  def restore
    raise RestoreFail unless ApplicationDatabase.new.restore(backup_file)
  end
end
