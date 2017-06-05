class ApplicationDatabase::MysqlAdapter
  attr_accessor :db_config

  def initialize(db_config)
    @db_config = db_config
  end

  def contents
    raise "Not yet implemented"
  end

  def restore_from_file(backfile)
    raise "Not yet implemented"
  end

  def restore_from_zipfile(backfile)
    raise "Not yet implemented"
  end

private

  def sql_restore_from_file(filename)
  end

  def sql_restore_from_zipfile(filename)
  end

  def sql_restore
  end
end
