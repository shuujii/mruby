MRuby::Gem::Specification.new 'mruby-bin-mrbc' do |spec|
  spec.license = 'MIT'
  spec.author  = 'mruby developers'
  spec.summary = 'mruby compiler executable'
  spec.add_dependency 'mruby-compiler', :core => 'mruby-compiler'

  spec.libraries = [build.libmruby_core_static]
  spec.bins << 'mrbc'
end
