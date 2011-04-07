require 'spec_helper'

describe BigbluebuttonMeeting do

  it "should be reconized" do
    lambda { BigbluebuttonMeeting.new }.should_not raise_error
  end

  [:running, :has_been_forcibly_ended, :room].each do |attr|
    it { should respond_to(attr) }
    it { should respond_to(:"#{attr}=") }
  end

  context "equality" do
    let(:meeting1) {
      m = BigbluebuttonMeeting.new
      m.running = true
      m.has_been_forcibly_ended = false
      m.room = nil
      m
    }
    let(:meeting2) {
      m = BigbluebuttonMeeting.new
      m.running = false
      m.has_been_forcibly_ended = true
      m.room = nil
      m
    }
    let(:meeting3) {
      m = BigbluebuttonMeeting.new
      m.running = meeting1.running
      m.has_been_forcibly_ended = meeting1.has_been_forcibly_ended
      m.room = meeting1.room
      m
    }

    it { meeting1.should == meeting3 }
    it { meeting1.should_not == meeting2 }
    it { meeting2.should_not == meeting3 }
  end

  context "gets params from hash" do
    let(:hash) { {:running=>"false", :hasBeenForciblyEnded=>"true"} }
    let(:meeting) { BigbluebuttonMeeting.new }

    it "standard case" do
      meeting.from_hash(hash)
      meeting.running.should == false
      meeting.has_been_forcibly_ended.should == true
    end

    it "case insensitive" do
      hash[:running] = "TRue"
      hash[:hasBeenForciblyEnded] = "FalSE"
      meeting.from_hash(hash)
      meeting.running.should == true
      meeting.has_been_forcibly_ended.should == false
    end

  end

end
