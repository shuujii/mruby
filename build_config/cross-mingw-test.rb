STDOUT.sync = STDERR.sync = true unless Rake.application.options.always_multitask

MRuby::Build.new("cross-mingw") do |conf|
  conf.toolchain :visualcpp
  conf.gembox "full-core"
  conf.enable_test
  conf.enable_bintest
end
