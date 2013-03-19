$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "get_back/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "get_back"
  s.version     = GetBack::VERSION
  s.authors     = ["Les Nightingill"]
  s.email       = ["codehacker@comcast.net"]
  s.summary     = "database backup/restore utilities"
  s.description = "Rails engine with utilities for backup and restore of entire application database. Rack tasks included may be invoked by cron for periodically emailing backup file."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.12"
  s.add_development_dependency "mysql2"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "ruby-debug19"
end
