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
MRuby.each_target {|t| t.define_rules}

# load custom rules
load "#{MRUBY_ROOT}/tasks/core.rake"
load "#{MRUBY_ROOT}/tasks/mrblib.rake"
load "#{MRUBY_ROOT}/tasks/mrbgems.rake"
load "#{MRUBY_ROOT}/tasks/libmruby.rake"
load "#{MRUBY_ROOT}/tasks/benchmark.rake"
load "#{MRUBY_ROOT}/tasks/gitlab.rake"
load "#{MRUBY_ROOT}/tasks/doc.rake"

depfiles = MRuby.main_target.bins.map do |bin|
  install_path = MRuby.main_target.exefile("#{MRUBY_INSTALL_DIR}/#{bin}")
  source_path = MRuby.main_target.exefile("#{MRuby.main_target.build_dir}/bin/#{bin}")

  file install_path => source_path do |t|
    install_D t.prerequisites.first, t.name
  end

  install_path
end

linker_args = Array.new(5){[]}
MRuby.each_target do |t|
  t.gems.each do |gem|
    linker_args[0] << gem.linker.libraries
    linker_args[1] << gem.linker.library_paths
    linker_args[2] << gem.linker.flags
    linker_args[3] << gem.linker.flags_before_libraries
    linker_args[4] << gem.linker.flags_after_libraries
  end
end
MRuby.each_target do |t|
  t.gems.each {|gem| depfiles << gem.define_builder(*linker_args)}
  depfiles << t.libraries
  unless t == MRuby.main_target
    t.bins.each {|bin| depfiles << t.exefile("#{t.build_dir}/bin/#{bin}")}
  end
end
depfiles.flatten!

task :default => :all

desc "build all targets, install (locally) in-repo"
task :all => depfiles do
  puts
  puts "Build summary:"
  puts
  MRuby.each_target {|t| t.print_build_summary}
  MRuby::Lockfile.write
end

desc "run all mruby tests"
task :test => :all do
  MRuby.each_target do |t|
    %w[lib bin].each do |k|
      n = "test:#{k}:#{t.name}"
      Rake::Task[n].invoke if Rake::Task.task_defined?(n)
    end
  end
end

namespace :test do
  {lib: "run libmruby tests", bin: "run command binaries tests"}.each do |k, d|
    desc d
    task k do
      MRuby.each_target do |t|
        n = "test:#{k}:#{t.name}"
        Rake::Task[n].invoke if Rake::Task.task_defined?(n)
      end
    end
  end
end

MRuby.each_target do |t|
  if t.test_enabled?
    task "test:lib:#{t.name}" => :all do
      gem = t.gem(core: 'mruby-test')
      gem.setup
      gem.setup_compilers
      bin = t.exefile("#{t.build_dir}/bin/mrbtest")
      Rake::Task[bin].invoke
      if t == MRuby.main_target
        install_D bin, "#{MRUBY_INSTALL_DIR}/#{File.basename(bin)}"
      end
      t.run_test
    end
  end

  if t.bintest_enabled?
    task "test:bin:#{t.name}" => :all do
      t.run_bintest
    end
  end
end

desc "clean all built and in-repo installed artifacts"
task :clean do
  MRuby.each_target {|t| rm_rf t.build_dir}
  rm_f depfiles
  rm_f "#{MRUBY_INSTALL_DIR}/bin/mrbtest" if MRuby.main_target.test_enabled?
  puts "Cleaned up target build folder"
end

desc "clean everything!"
task :deep_clean => %w[clean doc:clean] do
  MRuby.each_target {|t| rm_rf t.gem_clone_dir}
  puts "Cleaned up mrbgems build folder"
end
