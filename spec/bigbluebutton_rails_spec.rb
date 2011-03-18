require 'spec_helper'

describe BigbluebuttonRails do
  it "should be a module" do
    BigbluebuttonRails.should be_a(Module)
  end

  it "should have an engine" do
    BigbluebuttonRails::Engine.new.should be_a_kind_of(Rails::Engine)
  end
end
