class GlacierDbArchive < GlacierArchive
  belongs_to :application_data_backup

  def archive_contents
    ApplicationDatabase.new.contents
  end
end
