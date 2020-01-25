# frozen_string_literal: true

MRuby.each_target do |build|
  if build.enable_gems?
    # set up all gems
    build.gems.each(&:setup)
    build.gems.check(build)

    # loader all gems
    legal = "#{build.build_dir}/LEGAL"
    init_c = "#{build.build_dir}/mrbgems/gem_init.c"
    init_obj = build.objfile(init_c.pathmap("%X"))
    init_gems = build.gems.select(&:generate_functions)
    build.libmruby_objs << init_obj
    file init_obj => [init_c, legal]
    file init_c => :generate_mrbgems_gem_init_c
    task :generate_mrbgems_gem_init_c do |t|
      def t.timestamp; Time.at(0) end
      code = <<-EOS.dup
/*
 * This file contains a list of all
 * initializing methods which are
 * necessary to bootstrap all gems.
 *
 * IMPORTANT:
 *   This file was generated!
 *   All manual changes will get lost.
 */

#include <mruby.h>

      EOS
      init_gems.each do |g|
        code << <<-EOS
void GENERATED_TMP_mrb_#{g.funcname}_gem_init(mrb_state*);
void GENERATED_TMP_mrb_#{g.funcname}_gem_final(mrb_state*);
        EOS
      end
      unless init_gems.empty?
        code << <<-EOS

static void
mrb_final_mrbgems(mrb_state *mrb)
{
  #{init_gems.map{|g| "GENERATED_TMP_mrb_#{g.funcname}_gem_final(mrb);"}*"\n  "}
}
        EOS
      end
      code << <<-EOS

void
mrb_init_mrbgems(mrb_state *mrb)
{
  #{init_gems.map{|g| "GENERATED_TMP_mrb_#{g.funcname}_gem_init(mrb);"}*"\n  "}
  #{"mrb_state_atexit(mrb, mrb_final_mrbgems);" unless init_gems.empty?}
}
      EOS
      if !File.exist?(init_c) || File.read(init_c) != code
        mkdir_p File.dirname(init_c)
        File.write(init_c, code)
      end
    end
  end

  # legal documents
  file legal => __FILE__ do
    mkdir_p File.dirname(legal)
    File.open(legal, "w") do |f|
      f.puts <<-EOS
Copyright (c) #{Time.now.year} mruby developers

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
      EOS

      if build.enable_gems?
        f.puts <<-EOS

Additional Licenses

Due to the reason that you choosed additional mruby packages (GEMS),
please check the following additional licenses too:
        EOS

        build.gems.map do |g|
          authors = [g.authors].flatten.sort!.join(", ")
          f.puts
          f.puts "GEM: #{g.name}"
          f.puts "Copyright (c) #{Time.now.year} #{authors}"
          f.puts "License: #{g.licenses}"
        end
      end
    end
  end
end
