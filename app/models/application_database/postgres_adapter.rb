class ApplicationDatabase::PostgresAdapter
  attr_accessor :db_config

  def initialize(db_config)
    @db_config = db_config
  end

  def zip_and_save_to_file(file)
    `#{dump_contents} | gzip -c > #{file.path}`
    $?.exitstatus.zero?
  end

  def zipped_contents
    `#{dump_contents} | gzip -c`
  end

  def extract_contents
    `#{dump_contents}`
  end

  def save_to_file(file)
    system(dump_to_file(file))
    $?.exitstatus.zero?
  end

  def restore_from_file(backfile)
    system(sql_restore_from_file(backfile.filename))
    $?.exitstatus.zero?
  end

  def restore_from_zipfile(backfile)
    system(sql_restore_from_zipfile(backfile.filename))
    $?.exitstatus.zero?
  end

private
  def dump_contents
    "#{pg_dump} --username=#{db_config['username']} --quote-all-identifiers --clean --blobs #{db_config['database']}"
  end

  def dump_to_file(file)
    "#{dump_contents}  > #{file}"
  end

  def sql_restore_from_file(filename)
    "#{sql_restore} -e \"source #{filename}\";"
  end

  def sql_restore_from_zipfile(filename)
    "gunzip < #{filename} | #{sql_restore};"
  end

  def psql
    `which psql`.strip
  end

  def pg_dump
    `which pg_dump`.strip
  end

  def sql_restore
    "#{psql} --database #{db_config['database']} --host=#{db_config['host']} --username=#{db_config['username']}"
  end
end