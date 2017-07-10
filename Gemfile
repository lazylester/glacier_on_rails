source "http://rubygems.org"

# Declare your gem's dependencies in glacier_on_rails.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# jquery-rails is used by the dummy application
gem "jquery-rails"

gem "pg"
# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'debugger'
gem 'webmock', :git => 'https://github.com/lazylester/webmock.git' # contains a patch... use this fork until the primary sources merges the patch
gem 'rspec-rails', :git => "https://github.com/rspec/rspec-rails.git", :ref => "ac759a3" # contains a patch which solves a problem surfacing with rails 5.1
gem 'rspec-core', :git => "https://github.com/rspec/rspec-core.git", :ref => "0e0584f" # required by the rspec-rails version, above
gem 'rspec-mocks', :git => "https://github.com/rspec/rspec-mocks.git", :ref => "4847ef0" # ditto
gem 'rspec-expectations', :git => "https://github.com/rspec/rspec-expectations.git", :ref => "5c4ca95" # ditto
gem 'rspec-support', :git => "https://github.com/rspec/rspec-support.git", :ref => "491e723" # ditto
gem "aws-sdk", "~> 2"
