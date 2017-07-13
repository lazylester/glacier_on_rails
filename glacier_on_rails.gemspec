# -*- encoding: utf-8 -*-
# stub: glacier_on_rails 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "glacier_on_rails"
  s.version = "0.9.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Les Nightingill"]
  s.date = "2017-07-12"
  s.description = "Rails engine for database backup/restore to/from Amazon Glacier, including file attachments."
  s.email = ["codehacker@comcast.net"]
  s.files = Dir.glob("{{app,config,db,lib,script,spec}/**/*,*}").reject{|f| f =~ /(cache|\.log|\.gem$)/}
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.11"
  s.summary = "database backup/restore utilities"

  s.add_runtime_dependency "rails", "~> 5.1"
  s.add_runtime_dependency "httparty", "~> 0.15.5"
  s.add_development_dependency "byebug", "~> 9.0", ">= 9.0.6"
  s.add_development_dependency("capybara", "~> 2.4")
  s.add_development_dependency 'selenium-webdriver', "~>3.4", ">=3.4.3"
  s.add_development_dependency 'poltergeist', "~> 1.15"
  s.add_development_dependency 'haml-rails', "~> 1.0"
  s.add_development_dependency 'coffee-rails', "~> 4.2", ">= 4.2.2"
  s.add_development_dependency 'database_cleaner', "~> 1.6", ">= 1.6.1"
end
