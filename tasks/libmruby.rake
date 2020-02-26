MRuby.each_target do |build|
  objs = build.libmruby_objs.flatten

  file build.libmruby_static => objs do |t|
    build.archiver.run t.name, t.prerequisites
  end

  file "#{build.build_dir}/lib/libmruby.flags.mak" => [__FILE__, *objs] do |t|
    mkdir_p File.dirname t.name
    File.open(t.name, 'w') do |f|
      l = %i[
        libraries library_paths
        flags flags_before_libraries flags_after_libraries
      ].each_with_object({}) do |n, l|
        l[n] = build.gems.map {|g| g.linker.send("#{n}")}
      end

      ld = build.linker
      [["CFLAGS",
        build.cc.all_flags],
       ["LIBS",
        "#{ld.option_library % 'mruby'} #{ld.library_flags(l[:libraries])}"],
       ["LDFLAGS",
        ld.all_flags([l[:library_paths], "#{build.build_dir}/lib"], l[:flags])],
       ["LDFLAGS_BEFORE_LIBS",
        [ld.flags_before_libraries, l[:flags_before_libraries]].flatten * " "],
       ["LDFLAGS_AFTER_LIBS",
        [ld.flags_after_libraries, l[:flags_after_libraries]].flatten * " "],
       ["LIBMRUBY_PATH",
        build.libmruby_static],
      ].each do |(k, v)|
        f.puts "MRUBY_#{k} = #{v}"
      end
    end
  end

  task :all => "#{build_dir}/lib/libmruby.flags.mak"
end
