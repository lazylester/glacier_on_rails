class ApplicationDatabase::PostgresAdapter < ApplicationDatabase::BaseAdapter
  class PgDumpCmdMissing < StandardError; end
  class PgRestoreCmdMissing < StandardError; end
  class PgRestoreFileMissing < StandardError; end

  RestoreExclusions = %w{ application_data_backups
                          application_data_backups_id_seq
                          application_data_backups_pkey
                          application_data_backups_glacier_file_archives
                          glacier_archives
                          glacier_archives_id_seq
                          glacier_archives_pkey
                          SCHEMA }
  RestoreList = GlacierArchive::BackupFileDir.join('restore.list')
  Tempfile = GlacierArchive::BackupFileDir.join('tempfile')

  def contents
    `#{pg_dump} -w -Fc -U #{db_config['user']} #{db_config['database']}`
  end

  def restore(file)
    # 2>/dev/null as there are warning messages due to the --clean options if a table is not present
    # in the db but IS present in the backup file
    raise PgRestoreFileMissing unless File.exists? file
    restore_from_list(file)
  end

private
  def object_restoral_list(file)
    restore_list = GlacierArchive::BackupFileDir.join('restore.list')
    tempfile = GlacierArchive::BackupFileDir.join('tempfile')
    system("#{pg_restore} --clean -l --dbname=#{db_config['database']} #{file} > #{restore_list}")
    system("grep -v '#{RestoreExclusions.join('\|')}' #{restore_list} > #{tempfile} && cat #{tempfile} > #{restore_list} && rm #{tempfile}") # easier with grep than ruby!
    restore_list
  end

  def restore_from_list(file)
    list = object_restoral_list(file)
    system("#{pg_restore} --clean --dbname=#{db_config['database']} -L #{list} #{file} 2>/dev/null && rm #{list} && rm #{file}")
    $?.exitstatus.zero?
  end

  #def create_object_restoral_list(file)
    #object_list = `#{pg_restore} --clean -l --dbname=#{db_config['database']} #{file}` # -l option creates a list, capture it to the variable here
    #File.open RestoreList, 'w+' do |file|
      #file.write object_list.lines.reject(&RestoreExclusionsRegexp.method(:match)).join # wow that's brilliant, see https://stackoverflow.com/a/23696043/451893
    #end
  #end

  #def restore_from_list(file)
    #create_object_restoral_list(file)
    #system("#{pg_restore} --dbname=#{db_config['database']} -L #{RestoreList} #{file} 2>/dev/null && rm #{RestoreList}")
    #puts "xit stat #{$?.exitstatus}"
    #$?.exitstatus.zero?
    #true
  #end


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
