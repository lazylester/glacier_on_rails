# -*- encoding: utf-8 -*-
# stub: get_back 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "get_back"
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Les Nightingill"]
  s.date = "2014-05-17"
  s.description = "Rails engine with utilities for backup and restore of entire application database. Rack tasks included may be invoked by cron for periodically emailing backup file."
  s.email = ["codehacker@comcast.net"]
  s.files = ["app/assets", "app/assets/images", "app/assets/images/get_back", "app/assets/javascripts", "app/assets/javascripts/get_back", "app/assets/javascripts/get_back/application.js", "app/assets/stylesheets", "app/assets/stylesheets/get_back", "app/assets/stylesheets/get_back/application.css", "app/controllers", "app/controllers/get_back", "app/controllers/get_back/application_controller.rb", "app/controllers/get_back/backups_controller.rb", "app/helpers", "app/helpers/get_back", "app/helpers/get_back/application_helper.rb", "app/models", "app/models/application_database.rb", "app/models/backup_file.rb", "app/models/backup_mailer.rb", "app/views", "app/views/get_back", "app/views/get_back/backup_mailer", "app/views/get_back/backup_mailer/backup_file.html.erb", "app/views/get_back/backups", "app/views/get_back/backups/index.html.haml", "config/initializers", "config/initializers/time_formats.rb", "config/routes.rb", "lib/get_back", "lib/get_back/engine.rb", "lib/get_back/version.rb", "lib/get_back.rb", "lib/tasks", "lib/tasks/backup.rake", "lib/tasks/email_backup.rake", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.11"
  s.summary = "database backup/restore utilities"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rails>, [">= 0"])
      s.add_development_dependency(%q<mysql2>, [">= 0"])
      s.add_development_dependency(%q<minitest>, [">= 0"])
      s.add_development_dependency(%q<rspec-rails>, [">= 0"])
      s.add_development_dependency(%q<ruby-debug19>, [">= 0"])
    else
      s.add_dependency(%q<rails>, [">= 0"])
      s.add_dependency(%q<mysql2>, [">= 0"])
      s.add_dependency(%q<minitest>, [">= 0"])
      s.add_dependency(%q<rspec-rails>, [">= 0"])
      s.add_dependency(%q<ruby-debug19>, [">= 0"])
    end
  else
    s.add_dependency(%q<rails>, [">= 0"])
    s.add_dependency(%q<mysql2>, [">= 0"])
    s.add_dependency(%q<minitest>, [">= 0"])
    s.add_dependency(%q<rspec-rails>, [">= 0"])
    s.add_dependency(%q<ruby-debug19>, [">= 0"])
  end
end
