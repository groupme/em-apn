require 'bundler/gem_tasks'

desc "Run specs"
task :spec do
  spec_files = Dir["spec/**/*_spec.rb"]
  ruby("-S bundle exec rspec #{spec_files.join(" ")}")
end

task :default => :spec
