require 'mharris_ext'
require File.dirname(__FILE__) + "/adv_accessor/dsl"

module AdvAccessor
  class Base
    include FromHash
    attr_accessor :method
    attr_accessor :null_value
    attr_accessor :reader
    def value=(x)
      @input_value = @value = x
    end
    def raw_value
      return @value if @value
      @value = null_value[] if null_value
      @value
    end
    def basic_value
      res = raw_value
      res = reader[res] if reader
      res
    end
    def value(type=nil)
      return basic_value unless type
      special_reader_value(type)
    end
    fattr(:mappings) { AdvAccessor::Mappings.new }
    fattr(:readers) { AdvAccessor::Readers.new }
    def mapped_value(cls)
      mappings.mapped_value(:from => value.class, :to => cls, :base => self)
    end
    def special_reader_value(name)
      readers.mapped_value(:name => name, :base => self)
    end
  end
  class Mapping
    attr_accessor :from, :to, :block
    include FromHash
    def match?(ops)
      from == ops[:val].class && to == ops[:to]
    end
  end
  class Reader
    attr_accessor :name, :block
    include FromHash
    def match?(ops)
      name == ops[:name]
    end
  end
  class BaseReaders
    fattr(:list) { [] }
    def <<(x)
      self.list << x
    end
    def mapped_value(ops)
      ops[:val] = ops[:base].value
      list.each do |m|
        if m.match?(ops)
          return m.block[ops[:base]]
        end
      end
      raise "cant convert #{ops.inspect}"
    end
  end
  class Mappings < BaseReaders
    def add(ops,&b)
      ops.each do |from,to|
        self << Mapping.new(:from => from, :to => to, :block => b)
      end
    end
  end
  class Readers < BaseReaders
    def add(name,&b)
      self << Reader.new(:name => name, :block => b)
    end
  end
  class Checker
    include FromHash
    attr_accessor :obj
    def match?(o)
      if obj.kind_of?(Proc)
        !!obj[o]
      elsif obj.kind_of?(Class)
        o.kind_of?(obj)
      elsif obj.kind_of?(Regexp)
        !!(o =~ obj)
      else
        o == obj
      end
    end
  end
end