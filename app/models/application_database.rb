require 'fileutils'

class ApplicationDatabase
  def initialize
    @@db_config = ActiveRecord::Base.configurations[Rails.env]
    @@password = @@db_config['password'].nil? ? '' : "--password=#{@@db_config['password']}"
  end

  def self.extract_contents
    new
    %x[#{@@db_config['path']}mysqldump -u #{@@db_config['username']} #{@@password} --single-transaction -Q --add-drop-table -O add-locks=FALSE -O lock-tables=FALSE --hex-blob #{@@db_config['database']}]
  end

  def self.save_to_file(file)
    new
    system(sql_dump_to_file(file))
  end

  # argument is an instance of BackupFile
  def self.restore_from_file(backfile)
    new
    system(sql_restore(backfile.filename))
    $?.exitstatus.zero?
  end

private
  def self.sql_dump_to_file(file)
    sql_cmd =<<-SQL
    #{@@db_config['path']}mysqldump\
      -u #{@@db_config['username']} #{@@password}\
      --single-transaction\
      --quote-names\
      --add-drop-table\
      --add-locks=FALSE\
      --lock-tables=FALSE\
      --hex-blob #{@@db_config['database']} > #{file}
    SQL
  end

  def self.sql_restore(filename)
    sql_cmd =<<-SQL
    #{@@db_config['path']}mysql\
      --database #{@@db_config['database']}\
      --host=#{@@db_config['host']}\
      --user=#{@@db_config['username']} #{@@password}\
      -e "source #{filename}";
    SQL
  end

end
