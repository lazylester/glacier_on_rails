class ApplicationDatabase::PostgresAdapte  attr_accessor :db_config

  def initialize(db_config)
    @db_config = db_config
  end

  def zipped_contents
    system("touch tmp/temp_file.gz")
    system("#{pg_dump} -w -Fc --dbname=#{db_connection_uri} > tmp/temp_file.gz")
    File.read("tmp/temp_file.gz")
  end

  def zip_and_save_to_file(file)
    system("touch #{file}")
    # see http://stackoverflow.com/a/31599308/451893
    system("#{pg_dump} -w -Fc --dbname=#{db_connection_uri} > #{file}")
    $?.exitstatus.zero?
  end

  def save_to_file(file)
    system("touch #{file}")
    system("#{pg_dump} -w -Fp --clean --dbname=#{db_connection_uri} > #{file}")
    $?.exitstatus.zero?
  end

  def restore_from_file(file)
    system("#{psql} --dbname=#{db_connection_uri} < #{file}")
    $?.exitstatus.zero?
  end

  def restore_from_zipfile(file)
    system("#{pg_restore} --clean --dbname=#{db_connection_uri} #{file}")
    $?.exitstatus.zero?
  end

private

  def db_connection_uri
    "postgresql://#{db_config['user']}:#{db_config['password']}@127.0.0.1:5432/#{db_config['database']}"
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
