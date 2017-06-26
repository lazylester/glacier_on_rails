class ApplicationDatabase
  attr_accessor :adapter
  RequiredKeys = %w{username host database encoding adapter}
  DbConfig = ActiveRecord::Base.configurations[Rails.env]

  def initialize
    @adapter = case db_config["adapter"]
               when "postgresql"
                 PostgresAdapter.new(db_config)
               when "mysql"
                 MysqlAdapter.new(db_config)
               end
  end

  def db_config
    missing_keys = RequiredKeys - DbConfig.keys
    raise "#{missing_keys.join(' and ')} must be specified in config/database.yml" unless missing_keys.empty?
    DbConfig
  end

  delegate :contents, :restore, :to => :adapter
end
