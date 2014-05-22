require 'spec_helper'

describe BigbluebuttonAttendee do

  it "should be recognized" do
    lambda { BigbluebuttonAttendee.new }.should_not raise_error
  end

  [:user_id, :full_name, :role].each do |attr|
    it { should respond_to(attr) }
    it { should respond_to(:"#{attr}=") }
  end

  context "equality" do
    let(:attendee1) {
      attendee = BigbluebuttonAttendee.new
      attendee.user_id = Forgery(:basic).password
      attendee.full_name = Forgery(:name).full_name
      attendee.role = :attendee
      attendee
    }
    let(:attendee2) {
      attendee = BigbluebuttonAttendee.new
      attendee.user_id = Forgery(:basic).password
      attendee.full_name = Forgery(:name).full_name
      attendee.role = :moderator
      attendee
    }
    let(:attendee3) {
      attendee = BigbluebuttonAttendee.new
      attendee.user_id = attendee1.user_id
      attendee.full_name = attendee1.full_name
      attendee.role = attendee1.role
      attendee
    }

    it { attendee1.should == attendee3 }
    it { attendee1.should_not == attendee2 }
    it { attendee2.should_not == attendee3 }
  end

  context "gets params from hash" do
    let(:hash) { {:userID=>"user_id", :fullName=>"House M.D.", :role=>"MODERATOR"} }
    let(:attendee) { BigbluebuttonAttendee.new }

    it "standard case" do
      attendee.from_hash(hash)
      attendee.user_id.should == "user_id"
      attendee.full_name.should == "House M.D."
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
