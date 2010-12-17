require 'ostruct'
module AdvAccessor
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
    include FromHash
    attr_accessor :base
    fattr(:list) { [] }
    def <<(x)
      self.list << x
    end
    def get(ops)
      ops[:val] ||= base.value
      list.each do |m|
        if m.match?(ops)
          os = OpenStruct.new(:value => ops[:val], :raw_value => base.raw_value)
          return m.block[os]
        end
      end
      raise "cant convert #{ops.inspect}"
    end
  end
  class Mappings < BaseReaders
    fattr(:act_on_array) { false }
    def add(ops,&b)
      ops.each do |from,to|
        self << Mapping.new(:from => from, :to => to, :block => b)
      end
    end
    def get(arg)
      arg = {:from => base.value.class, :to => arg} unless arg.kind_of?(Hash)
      arg[:from] ||= base.value.class
      if act_on_array && base.value.kind_of?(Array)
        base.value.map do |val|
          super(arg.merge(:val => val))
        end
      else
        super(arg)
      end
    end
  end
  class Readers < BaseReaders
    def add(name,cls=nil,&b)
      b = lambda { |x| base.mappings.get(cls) } if cls
      self << Reader.new(:name => name, :block => b)
    end
    def get(arg)
      arg = {:name => arg} unless arg.kind_of?(Hash)
      super(arg)
    end
  end
end
