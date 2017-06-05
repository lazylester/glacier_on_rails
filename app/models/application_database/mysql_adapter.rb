class ApplicationDatabase::MysqlAdapter
  attr_accessor :db_config

  def initialize(db_config)
    @db_config = db_config
  end

  def contents
    raise "Not yet implemented"
  end

  def restore(file)
    raise "Not yet implemented"
  end

end
