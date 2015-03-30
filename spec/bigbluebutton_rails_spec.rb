require 'spec_helper'

describe BigbluebuttonRails do
  it "should be a module" do
    BigbluebuttonRails.should be_a(Module)
  end

  it "should have be an engine" do
    BigbluebuttonRails::Engine.should be < Rails::Engine
  end
end
