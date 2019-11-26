MRuby::Lockfile.disable
MRuby::Build.new do |conf|
  conf.toolchain :visualcpp
  conf.enable_debug
  conf.enable_test
  conf.gem core: 'mruby-bin-mruby'
  conf.gem core: 'mruby-print'
end
