module AdvAccessor
  def self.included(mod)
    mod.send(:extend,AdvAccessor::DSL::BaseInclude)
  end
  module DSL
    class Base
      attr_accessor :base
      include FromHash
      def method_missing(sym,*args,&b)
        base.send(sym,*args,&b)
      end
    end
    
    module BaseInclude
      def adv_accessor(name,&b)
        @adv_accessor ||= {}
        @adv_accessor[name] ||= AdvAccessor::Base.new(:method => name)
        base = @adv_accessor[name]
        dsl = AdvAccessor::DSL::Base.new(:base => base)
        
        if block_given?
          block = b
          if b.arity == 0
            block = lambda { |a| a.null_value = b }
          end
          block[dsl] 
        end
        
        define_method(name) do
          base.value
        end
        define_method("#{name}=") do |arg|
          base.value = arg
        end
      end
    end
  end
end