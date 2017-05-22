class ApplicationDatabase::PostgresAdapter
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

  def zip_and_save_to_file(file)
    system("touch #{file}")
    # see http://stackoverflow.com/a/31599308/451893
    system("#{pg_dump} -w -Fc #{db_config['database']} > #{file}")
    $?.exitstatus.zero?
  end

  def save_to_file(file)
    system("touch #{file}")
    system("#{pg_dump} -w -Fp --clean #{db_config['database']} > #{file}")
    $?.exitstatus.zero?
  end

  def restore_from_file(file)
    ActiveRecord::Base.connection.execute(File.read(file))
  end

  def restore_from_zipfile(file)
    # 2>/dev/null as there are warning messages due to the --clean options if a table is not present
    # in the db but IS present in the backup file
    system("#{pg_restore} --clean --dbname=#{db_config['database']} #{file} 2>/dev/null")
    $?.exitstatus.zero?
  end

private
  # alternative access to db using --dbname=#{db_connection_uri}
  def db_connection_uri
    "postgresql://#{db_config['username']}:#{db_config['password']}@127.0.0.1:5432/#{db_config['database']}"
  end

  def psql
    `which psql`.strip
  end

  def pg_dump
    `which pg_dump`.strip
  end

  def pg_restore
    `which pg_restore`.strip
  end

end
