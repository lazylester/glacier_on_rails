class ApplicationDatabase::PostgresAdapter
  class PgDumpMissing < StandardError; end
  class PgRestoreMissing < StandardError; end

  attr_accessor :db_config

  def initialize(db_config)
    @db_config = db_config
  end

  def zipped_contents
    temp_file = Rails.root.join('tmp','temp_file.gz').to_s
    system("touch #{temp_file}")
    system("#{pg_dump} -w -Fc #{db_config['database']} > #{temp_file}")
    File.read(temp_file)
  end

  def restore(file)
    # 2>/dev/null as there are warning messages due to the --clean options if a table is not present
    # in the db but IS present in the backup file
    system("#{pg_restore} --clean --dbname=#{db_config['database']} #{file} 2>/dev/null")
    $?.exitstatus.zero?
  end

private
  def pg_dump
    dump_cmd = `which pg_dump`.strip
    raise PgDumpMissing if dump_cmd.blank?
    dump_cmd
  end

  def pg_restore
    restore_cmd = `which pg_restore`.strip
    raise PgRestoreMissing if restore_cmd.blank?
    restore_cmd
  end

end
