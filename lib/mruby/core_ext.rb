autoload :Pathname, 'pathname'

class Object
  class << self
    def attr_block(*syms)
      syms.flatten.each do |sym|
        class_eval "def #{sym}(&block);block.call(@#{sym}) if block_given?;@#{sym};end"
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


def shellquote(s)
  if ENV['OS'] == 'Windows_NT'
    "\"#{s}\""
  else
    "'#{s}'"
  end
end

def install_D(src, dst)
  rm_f dst
  mkdir_p File.dirname(dst)
  cp src, dst
end

def _pp(cmd, src, tgt=nil, indent: nil)
  width = 5
  template = indent ? "%#{width * indent}s %s %s" : "%-#{width}s %s %s"
  puts template % [cmd, src, tgt ? "-> #{tgt}" : nil]
end
