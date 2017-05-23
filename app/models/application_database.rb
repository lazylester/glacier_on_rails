class ApplicationDatabase
  attr_accessor :adapter

  def initialize
    db_config = ActiveRecord::Base.configurations[Rails.env]
    @adapter = case db_config["adapter"]
               when "postgresql"
                 PostgresAdapter.new(db_config)
               when "mysql"
                 MysqlAdapter.new(db_config)
               end
  end

  delegate :zipped_contents, :restore, :to => :adapter
end
