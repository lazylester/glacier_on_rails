class AwsLog
  LogFile = File.join(Rails.root, 'log', 'aws.log')
  class << self
    cattr_accessor :logger
    delegate :debug, :info, :warn, :error, :fatal, :to => :logger
  end
end
