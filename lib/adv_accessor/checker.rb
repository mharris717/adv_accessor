module AdvAccessor
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