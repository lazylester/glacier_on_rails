require "rspec/core/rake_task"
require "bundler/gem_tasks"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
RSpec::Core::RakeTask.module_eval do
  def pattern
    files = []
    files << File.expand_path( 'spec/features/*_spec.rb', __FILE__ ).to_s
    files << File.expand_path( 'spec/models/*_spec.rb', __FILE__ ).to_s
  end
end

