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
      base.mappings.get(String).should == "13X"
    end
    it "should raw exception if value can't be mapped" do
      lambda { base.mappings.get(Symbol) }.should raise_error(Exception)
    end
  end
  describe "mapped array value" do
    before do
      @base = AdvAccessor::Base.new
      base.mappings.act_on_array = true
      base.mappings.add(Fixnum => String) { |x| x.value.to_s + "X" }
      base.value = [1,2]
    end
    it "should get mapped value" do
      base.mappings.get(String).should == ["1X","2X"]
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
  fattr(:f) { @Foo.new }
  def aa
    @Foo.instance_eval { @adv_accessor }
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
  describe 'mapped reader' do
    before do
      @Foo.adv_accessor(:bar) do |a|
        a.num { |a| a.value.to_i }
      end
      f.bar = "15"
    end
    it "should have value" do
      @Foo.instance_eval { @adv_accessor }[:bar].value.should == "15"
    end
    it "should have reader value in base" do
      
      @Foo.instance_eval { @adv_accessor }[:bar].readers.get(:num).should == 15
    end
    it "should have reader value access with method" do
      f.bar.num.should == 15
    end
    it "should have raw access with method" do
      f.bar.raw.should == '15'
    end
  end
  describe 'mapped reader by class - verbose' do
    before do
      @Foo.adv_accessor(:bar) do |a|
        a.mappings.add(String => Fixnum) { |x| x.value.to_i }
        a.num(Fixnum)
      end
      f.bar = "15"
    end
    it 'should have mapping set' do
      aa[:bar].mappings.get(Fixnum).should == 15
    end
    it "should have accessor" do
      f.bar.num.should == 15
    end
  end
  describe 'mapped reader by class - concise' do
    before do
      @Foo.adv_accessor(:bar) do |a|
        a.num(String => Fixnum) { |x| x.value.to_i }
      end
      f.bar = "15"
    end
    it 'should have mapping set' do
      aa[:bar].mappings.get(Fixnum).should == 15
    end
    it "should have accessor" do
      f.bar.num.should == 15
    end
  end
  describe 'mapped reader by class - array' do
    before do
      @Foo.adv_accessor(:bar) do |a|
        a.mappings.act_on_array = true
        a.num(String => Fixnum) { |x| x.value.to_i }
      end
      f.bar = ["1","2"]
    end
    it 'should have mapping set' do
      aa[:bar].mappings.get(Fixnum).should == [1,2]
    end
    it "should have accessor" do
      f.bar.num.should == [1,2]
    end
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