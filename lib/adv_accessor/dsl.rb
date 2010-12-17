module AdvAccessor
  def self.included(mod)
    mod.send(:extend,AdvAccessor::DSL::BaseInclude)
  end
  module DSL
    class Create
      attr_accessor :base, :complex
      include FromHash
      def method_missing(sym,*args,&b)
        if base.respond_to?(sym)
          base.send(sym,*args,&b)
        else
          self.complex = true
          if !block_given? && args.first.kind_of?(Proc)
            b = args.pop 
          end
          if args.first.kind_of?(Hash)
            h = args.pop
            mappings.add(h,&b)
            base.readers.add(sym,h.values.first)
          else
            base.readers.add(sym,*args,&b)
          end
          
        end
      end
    end
    class Access
      attr_accessor :base
      include FromHash
      def raw
        value
      end
      def method_missing(sym,*args,&b)
        if base.respond_to?(sym)
          base.send(sym,*args,&b)
        else
          base.readers.get(sym)
        end
      end
    end
    
    module BaseInclude
      def adv_accessor(name,&b)
        @adv_accessor ||= Hash.new { |h,k| h[k] = AdvAccessor::Base.new(:method => name) }

        base = @adv_accessor[name]
        dsl = AdvAccessor::DSL::Create.new(:base => base)
        
        complex_block = lambda do
          block = b
          if b.arity == 0
            block = lambda { |a| a.null_value = b }
          end
          block
        end
        
        create_writer = lambda do
          define_method("#{name}=") do |arg|
            base.value = arg
          end
        end
        
        create_simple = lambda do
          define_method(name) do
            base.value
          end
          create_writer[]
        end
        
        create_complex = lambda do
          define_method(name) do
            AdvAccessor::DSL::Access.new(:base => base)
          end
          create_writer[]
        end
        
        if block_given?
          complex_block[][dsl]
          if dsl.complex 
            create_complex[]
          else
            create_simple[]
          end
        end
        
      end
    end
  end
end