class ApplicationDatabase::PostgresAdapter
  attr_accessor :db_config

  def initialize(db_config)
    @db_config = db_config
  end

  def zipped_contents
    system("#{pg_dump} -Fc #{db_config['database']}")
  end

  def zip_and_save_to_file(file)
    system("touch #{file}")
    system("#{pg_dump} -Fc #{db_config['database']} > #{file}")
    $?.exitstatus.zero?
  end

  def save_to_file(file)
    system("touch #{file}")
    system("#{pg_dump} -Fp --clean #{db_config['database']} > #{file}")
    $?.exitstatus.zero?
  end

  def restore_from_file(file)
    system("#{psql} #{db_config['database']} < #{file}")
    $?.exitstatus.zero?
  end

  def restore_from_zipfile(file)
    system("#{pg_restore} --clean -d #{db_config['database']} #{file}")
    $?.exitstatus.zero?
  end

private

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
