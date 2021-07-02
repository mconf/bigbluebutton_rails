require 'spec_helper'

describe BigbluebuttonRails::Configuration do

  describe "#rooms_for_full_recording_sync" do
    let(:config) { BigbluebuttonRails::Configuration.new }

    it { expect(config.rooms_for_full_recording_sync).to be_a(Proc) }

    context "returns a query to find rooms that had meetings in the past 7 days" do
      let!(:room1) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting1) {
        create_time = DateTime.now.to_i * 1000
        FactoryGirl.create(:bigbluebutton_meeting, room: room1, create_time: create_time)
      }

      let!(:room2) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting2) {
        create_time = (DateTime.now - 1.day).to_i * 1000
        FactoryGirl.create(:bigbluebutton_meeting, room: room2, create_time: create_time)
      }

      let!(:room3) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting3) {
        create_time = (DateTime.now - 7.days).to_i * 1000
        FactoryGirl.create(:bigbluebutton_meeting, room: room3, create_time: create_time)
      }

      let!(:room4) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting4) {
        create_time = (DateTime.now - 7.days - 1.second).to_i * 1000
        FactoryGirl.create(:bigbluebutton_meeting, room: room4, create_time: create_time)
      }

      let!(:room5) { FactoryGirl.create(:bigbluebutton_room) }
      let!(:meeting5) {
        create_time = (DateTime.now - 8.days).to_i * 1000
        FactoryGirl.create(:bigbluebutton_meeting, room: room5, create_time: create_time)
      }

      let(:expected) { BigbluebuttonRoom.where(id: [room1.id, room2.id, room3.id]) }

      before { Timecop.freeze }
      after { Timecop.return }

      it { expect(config.rooms_for_full_recording_sync.call).to be_a(ActiveRecord::Relation) }
      it { expect(config.rooms_for_full_recording_sync.call.to_sql.should eql(expected.to_sql)) }
    end
  end
end
