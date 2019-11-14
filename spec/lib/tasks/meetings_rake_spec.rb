require 'spec_helper'

describe "bigbluebutton_rails:meetings:finish" do
  include_context "rake"

  before do
    BigbluebuttonRails::BackgroundTasks.stub(:finish_meetings)
  end

  it "requires environment" do
    subject.prerequisites.should include("environment")
  end

  it "calls the method that does the work" do
    subject.invoke
    BigbluebuttonRails::BackgroundTasks.should have_received(:finish_meetings)
  end
end