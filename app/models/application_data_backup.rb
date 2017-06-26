class ApplicationDataBackup < ActiveRecord::Base
  has_one :glacier_db_archive, :dependent => :destroy
  has_and_belongs_to_many :glacier_file_archives, association_foreign_key: 'glacier_file_archive_id', join_table: 'application_data_backups_glacier_file_archives'

  after_destroy do |application_data_backup|
    GlacierFileArchive.all.select{|gfa| gfa.application_data_backups.empty?}.each{|gfa| gfa.destroy}
  end

  before_create do |application_data_backup|
    application_data_backup.create_archive
  end

  def errors
    unless components(:nil?).any?
      components(:errors).map(&:full_messages).flatten.each do |message|
        super.add(:base, message)
      end
    end
    super
  end

  def create_archive
    self.glacier_db_archive = GlacierDbArchive.create
    self.glacier_file_archives = GlacierFileArchive.all!
  end

  def initiate_retrieval
    components(:initiate_retrieve_job)
  end

  def fetch_archive
    components(:fetch_archive)
    !has_errors?
  end

  def restore
    rehome_orphans
    components(:restore)
  end

  def retrieval_status
    # if any of the components has errors, just show status as 'available', an error message should be shown
    return  'available' if has_errors?
    # if components have different statuses, it's b/c they're not yet synchronized,
    # so take the 'lowest' status, where rank (high to low) is exists, local, ready, pending, available
    pick_lowest(components(:retrieval_status))
  end

  private
  # files that were added since the backup-being-restored was created
  # no longer have a reference in the database-being-restored.
  # instead of just deleting them, move them to a different location.
  # Any further disposition should be handled manually.
  def rehome_orphans
    files_to_be_restored = glacier_file_archives.map(&:filename)
    existing_files = ApplicationFile.list
    to_be_orphaned = existing_files - files_to_be_restored
    to_be_orphaned.each do |file|
      FileUtils.mv GetBack::Config.attached_files_directory.join(file), GetBack::Config.orphan_files_directory
    end
  end

  def has_errors?
    errors.full_messages.length > 0
  end

  def pick_lowest(statuses)
    rank = ["available","pending","ready","local","exists"] # low to high
    statuses.inject("exists"){|ref,stat| rank.index(stat) <= rank.index(ref) ? stat : ref }
  end

  def components(action)
    db_result = glacier_db_archive.send(action)
    glacier_file_archives.reject(&:exists_status?).collect { |archive| archive.send(action) } << db_result
  end
end
