require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "AdvAccessor::Base" do
  def base; @base; end
  describe "basic getting and setting" do
    before do
      @nv_log = []
      @base = AdvAccessor::Base.new
      base.null_value = lambda do
        @nv_log << "Called"
        13
      end
    end
    it "sets null value" do
      base.value.should == 13
    end
    it "only sets null value once" do
      3.times { |x| base.value }
      @nv_log.size.should == 1
      base.value.should == 13
    end
    it "can set value" do
      base.value = 14
      base.value.should == 14
      @nv_log.size.should == 0
    end
    it "can overwrite null value" do
      base.value.should == 13
      base.value = 14
      base.value.should == 14
    end
  end
  describe "mapped value" do
    before do
      @base = AdvAccessor::Base.new
      base.mappings.add(Fixnum => String) { |x| x.value.to_s + "X" }
      base.value = 13
    end
    it "should get mapped value" do
      base.mapped_value(String).should == "13X"
    end
    it "should raw exception if value can't be mapped" do
      lambda { base.mapped_value(Symbol) }.should raise_error(Exception)
    end
  end
  describe "reader, writer, raw" do
    before do
      @base = AdvAccessor::Base.new
      base.reader = lambda { |x| x * 2 }
      base.value = 13
    end
    it "should read" do
      base.value.should == 26
    end
    it 'has raw value' do
      base.raw_value.should == 13
    end
  end
  describe "special accessors" do
    before do
      @base = AdvAccessor::Base.new
      base.value = 13
      base.readers.add(:times_two) do |a|
        a.raw_value * 2
      end
    end
    it "should read" do
      base.value(:times_two).should == 26
    end
  end
end


describe "DSL" do
  before do
    @Foo = Class.new do
      include AdvAccessor
    end
  end
  it "smoke" do
    @Foo.adv_accessor(:bar)
  end
  it "basic accessor" do
    @Foo.adv_accessor(:bar) { 14 }
    @Foo.new.bar.should == 14
  end
  it 'complex accessor' do
    @Foo.adv_accessor(:bar) do |a|
      a.null_value = lambda { 14 }
    end
    @Foo.new.bar.should == 14
  end
  it 'basic writer' do
    @Foo.adv_accessor(:bar) { 14 }
    f = @Foo.new
    f.bar = 15
    f.bar.should == 15
  end
end

if false
class Foo
  adv_accessor :abc
  adv_accessor(:abc) do
    14
  end
  adv_accessor.complex(:abc) do |a|
    a.null_value = lambda { 14 }
  end
  adv_accessor.complex(:abc) do |a|
    a.reader = lambda do |a|
      a*2
    end
  end
  adv_accessor.complex(:grouping) do |a|
    a.cols = lambda do |a|
      a.raw.map { |f| f.kind_of?(DW::Field) ? f.col_alias : f }
    end
    a.fields = lambda do |a|
      a.cols.map { |x| new_sql_field(:field => x) }
    end
  end
  adv_accessor.complex(:grouping) do |a|
    a.mapping(String => DW::Field) { |x| new_sql_field(:field => x) }
    a.mapped_accessor(:cols => String, :fields => DW::Field)
  end
end
end