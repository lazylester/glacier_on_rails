# -*- encoding: utf-8 -*-
# stub: glacier_on_rails 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "glacier_on_rails"
  s.version = "0.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Les Nightingill"]
  s.date = "2014-05-17"
  s.description = "Rails engine with utilities for backup and restore of entire application database. Rack tasks included may be invoked by cron for periodically emailing backup file."
  s.email = ["codehacker@comcast.net"]
  s.files = `git ls-files -z`.split("\x0")
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.11"
  s.summary = "database backup/restore utilities to AWS Glacier"

  s.add_runtime_dependency("rails", "~> 5.0.0")
  s.add_runtime_dependency("httparty")
  s.add_development_dependency("mysql2")
  s.add_development_dependency("rspec-rails")
  s.add_development_dependency("byebug")
  s.add_development_dependency("capybara", "~> 2.4.0")
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'haml-rails'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'database_cleaner'
end
