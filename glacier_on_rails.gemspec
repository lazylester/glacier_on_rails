# -*- encoding: utf-8 -*-
# stub: glacier_on_rails 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "glacier_on_rails"
  s.version = "0.9.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Les Nightingill"]
  s.date = "2017-07-07"
  s.description = "Rails engine for database backup/restore to/from Amazon Glacier, including file attachments."
  s.email = ["codehacker@comcast.net"]
  #s.files = ["app/assets", "app/assets/images", "app/assets/images/glacier_on_rails", "app/assets/javascripts", "app/assets/javascripts/glacier_on_rails", "app/assets/javascripts/glacier_on_rails/application.js", "app/assets/stylesheets", "app/assets/stylesheets/glacier_on_rails", "app/assets/stylesheets/glacier_on_rails/application.css", "app/controllers", "app/controllers/glacier_on_rails", "app/controllers/glacier_on_rails/application_controller.rb", "app/controllers/glacier_on_rails/backups_controller.rb", "app/helpers", "app/helpers/glacier_on_rails", "app/helpers/glacier_on_rails/application_helper.rb", "app/models", "app/models/application_database.rb", "app/models/db_backup.rb", "app/models/backup_mailer.rb", "app/views", "app/views/glacier_on_rails", "app/views/glacier_on_rails/backup_mailer", "app/views/glacier_on_rails/backup_mailer/db_backup.html.erb", "app/views/glacier_on_rails/backups", "app/views/glacier_on_rails/backups/index.html.haml", "config/initializers", "config/initializers/time_formats.rb", "config/routes.rb", "lib/glacier_on_rails", "lib/glacier_on_rails/engine.rb", "lib/glacier_on_rails/version.rb", "lib/glacier_on_rails.rb", "lib/tasks", "lib/tasks/backup.rake", "lib/tasks/email_backup.rake", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.files = Dir.glob("{{app,config,db,lib,script,spec}/**/*,*}").reject{|f| f =~ /(cache|\.log|\.gem$)/}
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.11"
  s.summary = "database backup/restore utilities"

  s.add_runtime_dependency("rails", "~> 5.1.0")
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
