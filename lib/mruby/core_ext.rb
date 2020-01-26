# frozen_string_literal: true

autoload :Pathname, 'pathname'

class Object
  class << self
    def attr_block(*syms)
      syms.flatten.each do |sym|
        class_eval "def #{sym}(&b) b.call(@#{sym}) if b; @#{sym} end"
      end
    end
  end
end

class String
  def relative_path_from(dir)
    Pathname.new(File.expand_path(self)).relative_path_from(Pathname.new(File.expand_path(dir))).to_s
  end

  def relative_path
    relative_path_from(Dir.pwd)
  end
end

def install_D(src, dst)
  rm_f dst
  mkdir_p File.dirname(dst)
  cp src, dst
end

#
# call-seq:
#   erb(template)
#   erb(template, to)
#   erb(template, locals)
#   erb(template, to, context)
#   erb(template, to, locals)
#   erb(template, to, context, locals)
#
# Supported tags are only `<%=...%>` and `%` at the beginning of the line.
#
def erb(template, to=nil, context=self, locals={})
  to, locals = nil, to if to.kind_of?(Hash)
  context, locals = self, context if context.kind_of?(Hash)
  terms = template.split(/^(%)(.*?)(?:\n|\z) | (<%=)(.*?)%>/mx)
  code = "proc{|out__, locals__|\n".dup
  locals.each_key {|k| code << "#{k}=locals__[:#{k}]\n"}
  while term = terms.shift
    next if term.empty?
    case term
    when "%"; code << terms.shift
    when "<%="; code << "out__<<(#{terms.shift}).to_s"
    else code << "out__<<#{term.dump}"
    end
    code << "\n"
  end
  code << "out__\n"
  code << "}.('', locals)"
  result = context.instance_eval(code)
  if to
    mkdir_p File.dirname(to) unless File.exist?(to)
    File.write(to, result)
  end
  result
end

def _pp(cmd, src, tgt=nil, indent: nil)
  width = 5
  template = indent ? "%#{width * indent}s %s %s" : "%-#{width}s %s %s"
  puts template % [cmd, src, tgt ? "-> #{tgt}" : nil]
end