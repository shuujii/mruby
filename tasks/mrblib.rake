MRuby.each_target do |build|
  obj = build.objfile("#{build.build_dir}/mrblib/mrblib")
  mrblib_c = "#{build.build_dir}/mrblib/mrblib.c"
  rbfiles = Dir["mrblib/*.rb"].sort

  build.libmruby_objs << obj

  file obj => mrblib_c
  file mrblib_c => [mrbcfile, __FILE__].concat(rbfiles) do
    mkdir_p File.dirname(mrblib_c)
    File.open(mrblib_c, 'w') do |f|
      _pp "GEN", "*.rb", "#{mrblib_c.relative_path}"
      f.puts File.read("mrblib/init_mrblib.c")
      build.mrbc.run f, rbfiles, 'mrblib_irep'
    end
  end
end
