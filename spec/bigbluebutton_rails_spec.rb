require 'spec_helper'

describe BigbluebuttonRails do
  it "should be a module" do
    BigbluebuttonRails.should be_a(Module)
  end

  it "should have an engine" do
    BigbluebuttonRails::Engine.new.should be_a_kind_of(Rails::Engine)
  end

  describe "#value_to_boolean" do
    it { BigbluebuttonRails::value_to_boolean("true").should be_true }
    it { BigbluebuttonRails::value_to_boolean("1").should be_true }
    it { BigbluebuttonRails::value_to_boolean(1).should be_true }
    it { BigbluebuttonRails::value_to_boolean(true).should be_true }
    it { BigbluebuttonRails::value_to_boolean("t").should be_true }
    it { BigbluebuttonRails::value_to_boolean("false").should be_false }
    it { BigbluebuttonRails::value_to_boolean("0").should be_false }
    it { BigbluebuttonRails::value_to_boolean(0).should be_false }
    it { BigbluebuttonRails::value_to_boolean(false).should be_false }
    it { BigbluebuttonRails::value_to_boolean("f").should be_false }
  end
end
