MRuby::Toolchain.new(:clang) do |conf, _params|
  toolchain :gcc, default_command: 'clang'

  conf.compilers.each do |compiler|
    compiler.flags << '-Wzero-length-array' unless ENV['CFLAGS']
  end
  conf.cxx.flags << '-Wzero-length-array' unless ENV['CXXFLAGS'] || ENV['CFLAGS']
end
