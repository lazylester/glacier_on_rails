# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../dummy/config/environment.rb",  __FILE__)
require 'rspec/rails'
require 'byebug'
require 'webmock/rspec'
require 'capybara/poltergeist'
require 'selenium-webdriver'
include WebMock::API
require 'database_cleaner'

ENGINE_RAILS_ROOT=File.join(File.dirname(__FILE__), '../')
# this is intended to be the Capistrano shared files directory.
# in development we store them in tmp
# in production it's typically at ../shared
GetBack::Engine::TempDirectory = Rails.root.join('tmp')

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(ENGINE_RAILS_ROOT, "spec/support/**/*.rb")].each {|f| require f }

Capybara.register_driver :chrome do |app|
  #caps = Selenium::WebDriver::Remote::Capabilities.chrome(
    #"chromeOptions" => {
      #"args" => [ "--window-size=1400,800"],
      #"prefs" => {"download.default_directory" => DownloadHelpers::PATH }
    #}
  #)
  #Capybara::Selenium::Driver.new(app, :browser => :chrome, :desired_capabilities => caps)
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end


Capybara.register_driver :poltergeist do |app|
# use this configuration to show the messages between poltergeist and phantomjs
  #Capybara::Poltergeist::Driver.new(app, :debug => true)
# use this configuration to enable the page.driver.debug interface
# see https://github.com/teampoltergeist/poltergeist
  #Capybara::Poltergeist::Driver.new(app, :inspector => true, :timeout => 300)
  Capybara::Poltergeist::Driver.new(:window_size => [1600,900])
end

if ENV["client"] =~ /(sel|ff)/i
  puts "Browser: Firefox via Selenium"
  Capybara.javascript_driver = :selenium
elsif ENV["client"] =~ /chr/i
  puts "Browser: Chrome"

  Capybara.javascript_driver = :chrome
elsif ENV["client"] =~ /ie/i
  puts "Browser: IE"
  CONFIGURATION FOR REMOTE TESTING OF IE
  require 'capybara/rspec'


  Capybara.server_port = 3010
  ip = `ifconfig | grep 'inet ' | grep -v 127.0.0.1 | cut -d ' ' -f2`.strip
  puts "this machine ip is #{ip}"

  Capybara.app_host = "http://#{ip}:#{Capybara.server_port}"
  Capybara.current_driver = :remote
  Capybara.javascript_driver = :remote
  Capybara.run_server = false
  Capybara.remote = true

else
  puts "Browser: Phantomjs via Poltergeist"

  Capybara.javascript_driver = :poltergeist
end


WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # NOTE:this creates db locking problems with pg_dump, psql etc when run from within tests
  #config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  #config.order = "random"

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end

  config.before(:each) do |example|
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  config.after(:each) do
    DatabaseCleaner.clean
  end

end
