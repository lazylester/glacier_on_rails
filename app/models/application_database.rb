class ApplicationDatabase
  class ConfigurationError < StandardError
    def initialize(message)
      AwsLog.error "#{self.class.name} exception: #{message}"
      super
    end
  end

  class MissingConfigurationKeys < ConfigurationError
    def initialize(missing_keys)
      message = "#{missing_keys.join(' and ')} must be specified in config/database.yml"
      super(message)
    end
  end

  attr_accessor :adapter
  RequiredKeys = %w{username database adapter}

  def initialize
    @adapter = case db_config["adapter"]
               when "postgresql"
                 PostgresAdapter.new(db_config)
               when "mysql"
                 MysqlAdapter.new(db_config)
               end
  rescue ConfigurationError
    @adapter = Struct.new(:contents).new(nil)
  end

  def db_config
    config = ActiveRecord::Base.configurations[Rails.env]
    missing_keys = RequiredKeys - config.keys
    raise MissingConfigurationKeys.new(missing_keys) unless missing_keys.empty?
    config
  end

  delegate :contents, :restore, :to => :adapter
end
