# encoding: utf-8
# Build description.
# basic build file for mruby
MRUBY_ROOT = File.dirname(File.expand_path(__FILE__))
MRUBY_INSTALL_DIR = ENV['INSTALL_DIR'] || "#{MRUBY_ROOT}/bin"
MRUBY_BUILD_HOST_IS_CYGWIN = RUBY_PLATFORM.include?('cygwin')
MRUBY_BUILD_HOST_IS_OPENBSD = RUBY_PLATFORM.include?('openbsd')

Rake.verbose(false) if Rake.verbose == Rake::DSL::DEFAULT

$LOAD_PATH << File.join(MRUBY_ROOT, "lib")

# load build systems
require "mruby/core_ext"
require "mruby/build"

# load configuration file
MRUBY_CONFIG = (ENV['MRUBY_CONFIG'] && ENV['MRUBY_CONFIG'] != '') ? ENV['MRUBY_CONFIG'] : "#{MRUBY_ROOT}/build_config.rb"
load MRUBY_CONFIG

# load basic rules
MRuby::Build.each(&:define_rules)

# load custom rules
load "#{MRUBY_ROOT}/tasks/core.rake"
load "#{MRUBY_ROOT}/tasks/mrblib.rake"
load "#{MRUBY_ROOT}/tasks/mrbgems.rake"
load "#{MRUBY_ROOT}/tasks/libmruby.rake"
load "#{MRUBY_ROOT}/tasks/benchmark.rake"
load "#{MRUBY_ROOT}/tasks/gitlab.rake"
load "#{MRUBY_ROOT}/tasks/doc.rake"

depfiles = MRuby::Build.define_builder

task :default => :all

desc "build all targets, install (locally) in-repo"
task :all => depfiles do
  puts
  puts "Build summary:"
  puts
  MRuby::Build.each {|build| build.print_build_summary}
  MRuby::Lockfile.write
end

desc "build and run all mruby tests"
task :test => "test:build" do
  Rake::Task["test:run"].invoke
end

namespace :test do
  desc "build and run libmruby tests"
  task :lib => "test:build:lib" do
    Rake::Task["test:run:lib"].invoke
  end

  desc "build and run command binaries tests"
  task :bin => :all do
    Rake::Task["test:run:bin"].invoke
  end

  desc "build all mruby tests"
  task :build => "test:build:lib"

  namespace :build do
    desc "build libmruby tests"
    task :lib => :all do
      MRuby::Build.each do |build|
        next unless build.test_enabled?
        gem = build.gem(core: 'mruby-test')
        gem.setup
        gem.setup_compilers
        bin = build.exefile("#{build.build_dir}/bin/mrbtest")
        Rake::Task[bin].invoke
        install_D bin, "#{MRUBY_INSTALL_DIR}/#{File.basename(bin)}" if build.main?
      end
    end
  end

  desc "run all mruby tests"
  task :run do
    MRuby::Build.each do |build|
      build.run_test if build.test_enabled?
      build.run_bintest if build.bintest_enabled?
    end
  end

  namespace :run do
    desc "run libmruby tests"
    task :lib do
      MRuby::Build.each {|build| build.run_test if build.test_enabled?}
    end

    desc "run command binaries tests"
    task :bin do
      MRuby::Build.each{|build| build.run_bintest if build.bintest_enabled?}
    end
  end
end

desc "clean all built and in-repo installed artifacts"
task :clean do
  MRuby::Build.each {|build| rm_rf build.build_dir}
  rm_f depfiles
  rm_f "#{MRUBY_INSTALL_DIR}/bin/mrbtest" if MRuby::Build.main.test_enabled?
  puts "Cleaned up target build folder"
end

desc "clean everything!"
task :deep_clean => %w[clean doc:clean] do
  MRuby::Build.each {|build| rm_rf build.gem_clone_dir}
  puts "Cleaned up mrbgems build folder"
end
