class ApplicationDatabase::BaseAdapter
  attr_accessor :db_config

  def initialize(db_config)
    @db_config = db_config
  end
end
