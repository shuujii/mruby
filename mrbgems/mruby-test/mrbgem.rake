MRuby::Gem::Specification.new('mruby-test') do |spec|
  spec.license = 'MIT'
  spec.author  = 'mruby developers'
  spec.summary = 'mruby test'

  build.bins << 'mrbtest'

  spec.test_rbfiles = Dir.glob("#{MRUBY_ROOT}/test/t/*.rb")

  assert_rb = "#{MRUBY_ROOT}/test/assert.rb"
  assert_c = "#{build_dir}/assert.c"
  assert_obj = assert_c.ext(exts.object)
  assert_irep = "mrbtest_assert_irep"
  mrbtest_objs = build.gems.flat_map do |g|
    g.test_objs.dup << g.test_rbireps.ext(exts.object)
  end << assert_obj
  mrbtest_lib = libfile("#{build_dir}/mrbtest")
  linker_attrs = build.gem_linker_attrs

  build.gems.each do |g|
    file g.test_rbireps.ext(exts.object) => g.test_rbireps
    file g.test_rbireps => [g.test_rbfiles, build.mrbcfile, __FILE__].flatten do |t|
      _pp "GEN", t.name.relative_path
      erb <<-'EOS', t.name, assert_irep: assert_irep, g: g
%
% test_rbs = g.test_rbfiles.flatten
% test_ireps = test_rbs.map.with_index{|rb, i| "test_irep_#{i}"}
% if g.test_preload
%   test_preload = [g.dir, MRUBY_ROOT].map do |dir|
%     File.expand_path(g.test_preload, dir)
%   end.find {|file| File.exist?(file)}
%   test_preload_irep = "gem_test_irep_#{g.funcname}_preload"
% else
%   test_preload_irep = assert_irep
% end
% gem_table = build.gems.generate_gem_table(build)
% gem_deps = build.gems.tsort_dependencies(g.test_dependencies, gem_table).select(&:generate_functions)
%
/*
 * This file contains a test code for <%=g.name == name ? "the core" : "#{g.name} gem"%>.
 *
 * IMPORTANT: This file was generated! All manual changes will get lost.
 */

#include <stdio.h>
#include <stdlib.h>
#include <mruby.h>
#include <mruby/irep.h>
#include <mruby/variable.h>
% unless g.test_args.empty?
#include <mruby/hash.h>
% end

% if test_preload
<%=mrbc.run "", test_preload, test_preload_irep%>
% else
extern const uint8_t <%=assert_irep%>[];
% end

% test_rbs.zip(test_ireps) do |rb, irep|
/* <%=irep%>: <%=rb.relative_path%> */
<%=mrbc.run "", rb, "#{irep}", static: true%>
% end
% unless test_rbs.empty?
typedef void (*mrb_general_hook_t)(mrb_state*);

%   gem_deps.each do |d|
void <%=d.generated_hook_funcname(:init)%>(mrb_state *mrb);
void <%=d.generated_hook_funcname(:final)%>(mrb_state *mrb);
%   end
%   if g.custom_test_init?
void <%=g.hook_funcname(:test)%>(mrb_state *mrb);
%   end
void mrb_run_test_file(mrb_state *mrb,
                       mrb_value gem_name,
                       const mrb_general_hook_t *gem_dep_hooks,
                       mrb_general_hook_t custom_init_func,
                       const uint8_t *test_preload_irep,
                       const uint8_t *test_irep,
                       mrb_value test_args);
% end

void
<%=g.generated_hook_funcname(:test)%>(mrb_state *mrb)
{
% unless test_rbs.empty?
  mrb_value gem_name = mrb_obj_freeze(mrb, mrb_str_new_lit(mrb, "<%=g.name%>"));
%   if gem_deps.empty?
  const mrb_general_hook_t *gem_dep_hooks = NULL;
%   else
  const mrb_general_hook_t gem_dep_hooks[] = {
%     gem_deps.each do |d|
    <%=d.generated_hook_funcname(:init)%>,
    <%=d.generated_hook_funcname(:final)%>,
%     end
    NULL
  };
%   end
%   if g.test_args.empty?
  mrb_value test_args = mrb_undef_value();
%   else
  mrb_value test_args = mrb_hash_new_capa(mrb, <%=g.test_args.size%>);

%     g.test_args.each do |k, v|
  mrb_hash_set(
    mrb, test_args,
    mrb_obj_freeze(mrb, mrb_str_new_lit(mrb, <%=c_str_literal(k)%>)),
    mrb_obj_freeze(mrb, mrb_str_new_lit(mrb, <%=c_str_literal(v)%>)));
%     end
%   end

%   test_rbs.zip(test_ireps) do |rb, irep|
  /* <%=rb.relative_path%> */
  mrb_run_test_file(
    mrb, gem_name, gem_dep_hooks,
%     if g.custom_test_init?
    <%=g.hook_funcname(:test)%>,
%     else
    NULL,
%     end
    <%=test_preload_irep%>, <%=irep%>, test_args);
%   end
% end
}
      EOS
    end
  end

  file assert_obj => assert_c
  file assert_c => [assert_rb, build.mrbcfile] do |t|
    _pp "GEN", t.name.relative_path
    File.open(t.name, 'w') {|f| mrbc.run f, assert_rb, assert_irep}
  end

  file mrbtest_lib => mrbtest_objs do |t|
    build.archiver.run t.name, t.prerequisites
  end

  unless build.build_mrbtest_lib_only?
    exe = exefile("#{build.build_dir}/bin/mrbtest")
    mrbtest_c = "#{build_dir}/mrbtest.c"
    mrbtest_obj = mrbtest_c.ext(exts.object)
    driver_objs = srcs_to_objs(".")
    active_gems_txt = "#{build_dir}/active_gems.txt"

    file exe => [*driver_objs, mrbtest_obj, mrbtest_lib, build.libmruby_static] do |t|
      build.linker.run t.name, t.prerequisites, *linker_attrs
    end

    file mrbtest_obj => mrbtest_c
    file mrbtest_c => [active_gems_txt, build.mrbcfile, __FILE__] do |t|
      _pp "GEN", t.name.relative_path
      erb <<-'EOS', t.name
/*
 * This file contains a list of all test functions.
 *
 * IMPORTANT: This file was generated! All manual changes will get lost.
 */

struct mrb_state;
typedef struct mrb_state mrb_state;

% build.gems.each do |g|
void <%=g.generated_hook_funcname(:test)%>(mrb_state *mrb);
% end

void
mrbgemtest_init(mrb_state* mrb)
{
% build.gems.each do |g|
  <%=g.generated_hook_funcname(:test)%>(mrb);
% end
}
      EOS
    end
    task active_gems_txt do |t|
      active_gems = build.gems.sort_by(&:name).inject(""){|s, g| s << "#{g.name}\n"}
      if !File.exist?(t.name) || active_gems != File.read(t.name)
        mkdir_p File.dirname(t.name)
        File.write(t.name, active_gems)
        updated = true
      end
      t.singleton_class.send(:define_method, :foo) do
        Time.at(updated ? Float::MAX : 0)
      end
    end
  end

  def c_str_literal(obj)
    obj.to_s.inspect
  end
end
