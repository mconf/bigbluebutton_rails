require 'spec_helper'

describe BigbluebuttonUpdateServerConfigs do
  it "uses the queue :bigbluebutton_rails" do
    BigbluebuttonUpdateServerConfigs.instance_variable_get(:@queue).should eql(:bigbluebutton_rails)
  end
end
