require 'spec_helper'

describe BigbluebuttonRails do
  it "should be a module" do
    BigbluebuttonRails.should be_a(Module)
  end

  it "should have be an engine" do
    BigbluebuttonRails::Engine.should be < Rails::Engine
  end

  describe "#value_to_boolean" do
    it { BigbluebuttonRails::value_to_boolean("true").should be_truthy }
    it { BigbluebuttonRails::value_to_boolean("1").should be_truthy }
    it { BigbluebuttonRails::value_to_boolean(1).should be_truthy }
    it { BigbluebuttonRails::value_to_boolean(true).should be_truthy }
    it { BigbluebuttonRails::value_to_boolean("t").should be_truthy }
    it { BigbluebuttonRails::value_to_boolean("false").should be_falsey }
    it { BigbluebuttonRails::value_to_boolean("0").should be_falsey }
    it { BigbluebuttonRails::value_to_boolean(0).should be_falsey }
    it { BigbluebuttonRails::value_to_boolean(false).should be_falsey }
    it { BigbluebuttonRails::value_to_boolean("f").should be_falsey }
  end
end
