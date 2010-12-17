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
      readers.get(type)
    end
    fattr(:mappings) { AdvAccessor::Mappings.new(:base => self) }
    fattr(:readers) { AdvAccessor::Readers.new(:base => self) }
  end
end