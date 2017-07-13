class ApplicationDatabase::PostgresAdapter < ApplicationDatabase::BaseAdapter
  class PgDumpCmdMissing < StandardError; end
  class PgRestoreCmdMissing < StandardError; end
  class PgRestoreFileMissing < StandardError; end
  class PgPassFileMissing < StandardError
    def initialize
      message = "#{File.expand_path("~/.pgpass")} file not found, cannot dump database contents"
      AwsLog.error "ApplicationDatabase::PostgresAdapter::PgPassFileMissing exception: #{message}"
      super(message)
    end
  end

  RestoreExclusions = %w{ application_data_backups
                          glacier_archives
                          SCHEMA }

  RestoreList = GlacierArchive::BackupFileDir.join('restore.list')

  def contents
    raise PgPassFileMissing if db_config["password"].present? && !File.exists?("~/.pgpass")
    `#{pg_dump} -w -Fc -U #{db_config['username']} #{db_config['database']}`
  end

  def restore(file)
    raise PgRestoreFileMissing unless File.exists? file
    restore_from_list(file)
  end

private
  def generate_object_restoral_list(file)
    # generate the raw list of all objects
    system("#{pg_restore} --clean -n public -l #{file} > #{RestoreList}")
    # remove objects from the list that are enumerated in RestoreExclusions
    retained_lines = File.readlines(RestoreList).select{|line| !line.match(/#{RestoreExclusions.join("|")}/)}
    File.open RestoreList, 'w' do |file|
      file.write(retained_lines.join)
    end
  end

  def restore_from_list(file)
    generate_object_restoral_list(file)
    result = `#{pg_restore} --clean -n public -U #{db_config['username']} --dbname=#{db_config['database']} -L #{RestoreList} #{file} 2>&1`
    `rm #{RestoreList} && rm #{file}` if $?.exitstatus.zero?
    AwsLog.error result unless $?.exitstatus.zero?
    $?.exitstatus.zero?
  end

  def pg_dump
    dump_cmd = `which pg_dump`.strip
    raise PgDumpCmdMissing if dump_cmd.blank?
    dump_cmd
  end

  def pg_restore
    restore_cmd = `which pg_restore`.strip
    raise PgRestoreCmdMissing if restore_cmd.blank?
    restore_cmd
  end

end
