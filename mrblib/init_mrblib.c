
#include <mruby.h>
#include <mruby/irep.h>

void
mrb_init_mrblib(mrb_state *mrb)
{
  mrb_load_irep(mrb, mrblib_irep);
}
