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
    # TODO instead of creating a copy of the db in memory and writing to the file,
    # should try command output redirection (>) in the unix shell directly to the file, in the ApplicationController.extract_contents
    # method. This might avoid the memory problems that are causing the backups to fail.
    # see http://blog.craigambrose.com/articles/2007/03/01/a-rake-task-for-database-backups
    new
    %x[#{@@db_config['path']}mysqldump -u #{@@db_config['username']} #{@@password} --single-transaction -Q --add-drop-table -O add-locks=FALSE -O lock-tables=FALSE --hex-blob #{@@db_config['database']} > #{file} ]
  end

  def self.restore_from_file(backfile)
    # when it has been tested in production mode, replace the next two lines with new
    new_back = backfile.filename
    @db_config = ActiveRecord::Base.configurations["development"]    # TODO hard coded here... MUST CHANGE THIS AFTER TESTING
    password = @db_config['password'].nil? ? '' : "--password=#{@db_config['password']}"
    %x[#{@db_config['path']}mysql --database #{@db_config['database']} --host=#{@db_config['host']} --user=#{@db_config['username']} #{password} -e \"source #{new_back}\";]
    $?.exitstatus.zero?
  end

end
