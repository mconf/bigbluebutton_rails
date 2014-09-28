require 'spec_helper'

describe "bigbluebutton_rails:recordings:update" do
  include_context "rake"

  before do
    BigbluebuttonRails::BackgroundTasks.stub(:update_recordings)
  end

  it "requires environment" do
    subject.prerequisites.should include("environment")
  end

  it "calls the method that does the work" do
    subject.invoke
    BigbluebuttonRails::BackgroundTasks.should have_received(:update_recordings)
  end
end
