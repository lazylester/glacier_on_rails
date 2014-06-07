class BackupFile
  # here we mimic some of the ActiveRecord actions, but with the filesystem instead of a database table
  # BackupFile objects have a single attribute, filename, and use the global BACKUP_DIR constant

  attr_accessor :file


  # either returns all backup files (for index action) or the single file whose filename is passed-in (e.g. backups_2009-08-16_07-50-26_development_dump)
  def self.find(arg)
    backup_files = Dir.glob(File.join(BACKUP_DIR,"*.sql.gz"))

    case arg
    when :all
      res = backup_files.map{ |f| BackupFile.new(:filename=>f)}
    else
      fname = backup_files.detect{|d| d.include? arg } # could simply use the raw arg field as filename, but maybe better to check there's a file with this name?
      res = BackupFile.new(:filename=>fname)  # fname is the full path from filesystem root
    end
    res
  end

  def self.all
    self.find(:all)
  end

  def self.most_recent
    all.sort.last
  end

  def self.excess_above(n)
    number_of_backups = all.size
    if number_of_backups > n
      all.sort.shift(number_of_backups - n)
    end
  end

  def contents
    file.read
  end

  def gzipped
    ActiveSupport::Gzip.compress(contents)
  end

  def destroy
    begin
      FileUtils.remove_file(filename)
    rescue
      false
    end
  end

  # creates a new BackupFile object using the filename passed-in if it's present
  # or else generates a new filename representing the current date/time/environment
  def initialize(attributes={})
    datestamp = "backups_"+Time.now.strftime("%Y-%m-%d_%H-%M-%S")
    Dir.mkdir(BACKUP_DIR) unless File.exists?(BACKUP_DIR)
    new_filename = "#{datestamp}_#{Rails.env}_dump.sql.gz"
    full_file_path = BACKUP_DIR + new_filename
    if attributes[:filename]
      @file = File.new(attributes[:filename])
    elsif attributes[:dir]
      @file = File.new(Rails.root.join(attributes[:dir],new_filename), "w")
    else
      @file = File.new(full_file_path, "w")
    end
  end

  # the save action extracts the contents of the entire database for the current environment
  # and dumps it into the BackupFile#filename file
  def save
    ApplicationDatabase.zip_and_save_to_file(@file.path)
  end

  def filename
    @file.path
  end

  def filename_base
    File.basename(filename, ".sql.gz")
  end

  # extracts a time object from the filename of a backup file
	def date
   tt = Time.gm(*filename_base.scan(/\d+/))

   def tt.to_s
    to_formatted_s(:short_date_with_year) + "  " + to_formatted_s(:short_time)
   end

   tt
	end

  def <=>(other)
   date<=>other.date
  end

  # validation requires a match for the filename components:
  # does not validate contents!
	def valid?
    years =  ("2009"..Date.today.year.to_s)
    months = ("01".."12")
    days = ("01".."31")
    hours = ("00".."23")
    minutes = ("00".."60")
    seconds = ("00".."60")
    date = "("+[years, months, days].map { |f| f.to_a.join("|") }.join(")-(") + ")"
    time = "("+[hours, minutes, seconds].map { |f| f.to_a.join("|") }.join(")-(") + ")"
    reg = /^backups_#{date}_#{time}_(development|production)_dump.sql.gz/
    File.basename(filename_base+".sql.gz")=~reg
	end
end
