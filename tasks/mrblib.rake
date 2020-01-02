MRuby.each_target do
  obj = objfile("#{build_dir}/mrblib/mrblib")
  mrblib_c = "#{build_dir}/mrblib/mrblib.c"
  rbfiles = Dir.glob("mrblib/*.rb").sort

  self.libmruby_objs << obj

  file obj => mrblib_c
  file mrblib_c => [mrbcfile, __FILE__].concat(rbfiles) do |t|
    mkdir_p File.dirname(t.name)
    open(t.name, 'w') do |f|
      _pp "GEN", "*.rb", "#{t.name.relative_path}"
      f.puts File.read("mrblib/init_mrblib.c")
      mrbc.run f, rbfiles, 'mrblib_irep'
    end
  end
end
