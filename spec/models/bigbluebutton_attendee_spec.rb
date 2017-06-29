# coding: utf-8
require 'spec_helper'

describe BigbluebuttonAttendee do
  it "loaded correctly" do
    BigbluebuttonAttendee.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_attendee) }

  context "gets params from hash" do
    let(:hash) { {:userID=>"user_id", :fullName=>"House M.D.", :role=>"MODERATOR"} }
    let(:attendee) { BigbluebuttonAttendee.new }

    it "standard case" do
      attendee.from_hash(hash)
      attendee.user_id.should == "user_id"
      attendee.user_name.should == "House M.D."
      attendee.role.should == :moderator
    end

    it "converts user_id to string" do
      hash[:userID] = 123
      attendee.from_hash(hash)
      attendee.user_id.should == "123"
    end

    it "role is not case sensitive" do
      hash[:role] = "mODErAtOR"
      attendee.from_hash(hash)
      attendee.role.should == :moderator
    end

    it "any role other than 'moderator' is attendee" do
      hash[:role] = "VIEWER"
      attendee.from_hash(hash)
      attendee.role.should == :attendee

      hash[:role] = "whatever"
      attendee.from_hash(hash)
      attendee.role.should == :attendee
    end
  end
end
