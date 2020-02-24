MRuby.each_target do
  objs = []
  Dir.glob("src/*.c") do |f|
    next nil if cxx_exception_enabled? && File.basename(f) =~ /^(error|vm)\.c$/
    objs << objfile(f.pathmap("#{build_dir}/src/%n"))
  end

  if cxx_exception_enabled?
    %w(vm error).each do |v|
      objs << compile_as_cxx("src/#{v}.c", "#{build_dir}/src/#{v}.cxx")
    end
  end
  self.libmruby_objs << objs

  file libmruby_core_static => objs do |t|
    archiver.run t.name, t.prereqs
  end
end
