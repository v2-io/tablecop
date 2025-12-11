# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

desc "Run tests"
task default: :test

namespace :release do
  desc "Build the gem locally without releasing"
  task :build do
    system("gem build tablecop.gemspec")
  end

  desc "Install the gem locally"
  task install: :build do
    gemfile = Dir["tablecop-*.gem"].max_by { |f| File.mtime(f) }
    system("gem install #{gemfile}")
  end
end
