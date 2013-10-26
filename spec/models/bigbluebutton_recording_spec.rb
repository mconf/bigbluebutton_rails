# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonRecording do
  it "loaded correctly" do
    BigbluebuttonRecording.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should belong_to(:server) }
  it { should validate_presence_of(:server) }

  it { should belong_to(:room) }

  it { should belong_to(:meeting) }

  it { should validate_presence_of(:recordid) }
  it { should validate_uniqueness_of(:recordid) }

  [:recordid, :meetingid, :name, :published, :start_time,
   :end_time, :available].each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end

  it { should have_many(:metadata).dependent(:destroy) }

  it { should have_many(:playback_formats).dependent(:destroy) }

  context "scopes" do

    describe "#published" do
      before :each do
        @recording1 = FactoryGirl.create(:bigbluebutton_recording, :published => false)
        @recording2 = FactoryGirl.create(:bigbluebutton_recording, :published => true)
        @recording3 = FactoryGirl.create(:bigbluebutton_recording, :published => true)
      end
      it { BigbluebuttonRecording.published.should == [@recording2, @recording3] }
    end

  end

  describe "#to_param" do
    it { should respond_to(:to_param) }
    it {
      s = FactoryGirl.create(:bigbluebutton_recording)
      s.to_param.should be(s.recordid)
    }
  end

  describe ".sync" do
    let(:data) {
      [
       {
         :recordID => "recording-1",
         :meetingID => "meetingid-1",
         :name => "Evening Class1",
         :published => true,
         :startTime => DateTime.now,
         :endTime => DateTime.now + 2.hours,
         :metadata => {
           :course => "Fundamentals of JAVA",
           :description => "List of recordings",
           :activity => "Evening Class1"
         },
         :playback => { :format =>
           [
            { :type => "slides",
              :url => "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
              :length => 64
            },
            { :type => "presentation",
              :url => "http://test-install.blindsidenetworks.com/presentation/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
              :length => 64
            }
           ]
         }
       }
      ]
    }
    let(:new_server) { FactoryGirl.create(:bigbluebutton_server) }
    before {
      @room = FactoryGirl.create(:bigbluebutton_room, :meetingid => "meetingid-1")
    }

    context "adds new recordings" do
      before {
        BigbluebuttonRecording.sync(new_server, data)
        @recording = BigbluebuttonRecording.last
      }
      it { BigbluebuttonRecording.count.should == 1 }
      it { @recording.recordid.should == data[0][:recordID] }
      it { @recording.meetingid.should == data[0][:meetingID] }
      it { @recording.name.should == data[0][:name] }
      it { @recording.published.should == data[0][:published] }
      it { @recording.end_time.utc.to_i.should == data[0][:endTime].utc.to_i }
      it { @recording.start_time.utc.to_i.should == data[0][:startTime].utc.to_i }
      it { @recording.server.should == new_server }
      it { @recording.room.should == @room }
      it { @recording.available.should == true }
      it { @recording.metadata.count.should == 3 }
      3.times do |i|
        it { @recording.metadata[i].name.should == data[0][:metadata].keys[i].to_s }
        it { @recording.metadata[i].content.should == data[0][:metadata].values[i] }
      end
      it { @recording.playback_formats.count.should == 2 }
      2.times do |i|
        it { @recording.playback_formats[i].format_type.should == data[0][:playback][:format][i][:type] }
        it { @recording.playback_formats[i].url.should == data[0][:playback][:format][i][:url] }
        it { @recording.playback_formats[i].length.should == data[0][:playback][:format][i][:length] }
      end
    end

    context "updates existing recordings" do
      before {
        # pre-existing recording, with same id but the rest is different
        FactoryGirl.create(:bigbluebutton_recording, :recordid => data[0][:recordID])
        BigbluebuttonRecording.sync(new_server, data)
        @recording = BigbluebuttonRecording.last
      }
      it { BigbluebuttonRecording.count.should == 1 }
      it { @recording.recordid.should == data[0][:recordID] }
      it { @recording.meetingid.should == data[0][:meetingID] }
      it { @recording.name.should == data[0][:name] }
      it { @recording.published.should == data[0][:published] }
      it { @recording.end_time.utc.to_i.should == data[0][:endTime].utc.to_i }
      it { @recording.start_time.utc.to_i.should == data[0][:startTime].utc.to_i }
      it { @recording.server.should == new_server }
      it { @recording.room.should == @room }
      it { @recording.available.should == true }
      it { @recording.metadata.count.should == 3 }
      3.times do |i|
        it { @recording.metadata[i].name.should == data[0][:metadata].keys[i].to_s }
        it { @recording.metadata[i].content.should == data[0][:metadata].values[i] }
      end
      it { @recording.playback_formats.count.should == 2 }
      2.times do |i|
        it { @recording.playback_formats[i].format_type.should == data[0][:playback][:format][i][:type] }
        it { @recording.playback_formats[i].url.should == data[0][:playback][:format][i][:url] }
        it { @recording.playback_formats[i].length.should == data[0][:playback][:format][i][:length] }
      end
    end

    context "doesn't remove recordings" do
      before {
        # pre-existing recording that shouldn't be removed
        FactoryGirl.create(:bigbluebutton_recording)
        BigbluebuttonRecording.sync(new_server, data)
      }
      it { BigbluebuttonRecording.count.should == 2 }
    end

    context "sets recording that are not in the parameters as unavailable" do
      before {
        # pre-existing recordings that should be marked as unavailable
        @r1 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
        @r2 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
        BigbluebuttonRecording.sync(new_server, data)
        @r1.reload
        @r2.reload
      }
      it { BigbluebuttonRecording.count.should == 3 }
      it { @r1.available.should == false }
      it { @r2.available.should == false }
    end

    context "works for multiple recordings" do
      before {
        # adds 2 more recordings to the input data
        clone = data[0].clone
        clone[:recordID] = "recordid-2"
        data.push(clone)
        clone = data[0].clone
        clone[:recordID] = "recordid-3"
        data.push(clone)
        BigbluebuttonRecording.sync(new_server, data)
      }
      it { BigbluebuttonRecording.count.should == 3 }
    end

    context "uses transactions for each recording individually" do
      before {
        # this recording will fail when saving, so all associated data
        # should also NOT be saved
        clone = data[0].clone
        clone[:recordID] = "recordid-2"
        clone[:metadata] = "I will make it throw an exception"
        data.push(clone)
        lambda {
          BigbluebuttonRecording.sync(new_server, data)
        }.should raise_error(Exception)
      }
      it { BigbluebuttonRecording.count.should == 1 }
      it { BigbluebuttonMetadata.count.should == 3 }
      it { BigbluebuttonPlaybackFormat.count.should == 2 }
    end
  end

  describe ".update_recording" do
    let(:old_attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
    let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording, old_attrs) }
    let(:data) {
      {
        :recordid => attrs[:recordid],
        :meetingid => attrs[:meetingid],
        :name => attrs[:name],
        :published => !old_attrs[:published],
        :start_time => attrs[:start_time],
        :end_time => attrs[:end_time],
        :metadata => { :any => "any" },
        :playback => { :format => [ { :type => "any1" }, { :type => "any2" } ] }
      }
    }
    let(:new_server) { FactoryGirl.create(:bigbluebutton_server) }

    before {
      @room = FactoryGirl.create(:bigbluebutton_room, :meetingid => attrs[:meetingid])
      BigbluebuttonRecording.should_receive(:sync_additional_data)
        .with(recording, data)
      BigbluebuttonRecording.send(:update_recording, new_server, recording, data)
    }
    it { recording.recordid.should == old_attrs[:recordid] } # not updated
    it { recording.meetingid.should == attrs[:meetingid] }
    it { recording.name.should == attrs[:name] }
    it { recording.published.should == !old_attrs[:published] }
    it { recording.end_time.utc.to_i.should == attrs[:end_time].utc.to_i }
    it { recording.start_time.utc.to_i.should == attrs[:start_time].utc.to_i }
    it { recording.server.should == new_server }
    it { recording.room.should == @room }
  end

  describe ".create_recording" do
    let(:meeting_start_time) { DateTime.now }
    let(:recordid) { "#{SecureRandom.uuid}-#{meeting_start_time.to_i}" }
    let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
    let(:data) {
      {
        :recordid => recordid,
        :meetingid => attrs[:meetingid],
        :name => attrs[:name],
        :published => attrs[:published],
        :start_time => attrs[:start_time],
        :end_time => attrs[:end_time],
        :metadata => { :any => "any" },
        :playback => { :format => [ { :type => "any1" }, { :type => "any2" } ] }
      }
    }
    let(:new_server) { FactoryGirl.create(:bigbluebutton_server) }

    before {
      @room = FactoryGirl.create(:bigbluebutton_room, :meetingid => attrs[:meetingid])
      @meeting = FactoryGirl.create(:bigbluebutton_meeting, :room => @room, :start_time => meeting_start_time.utc)

      BigbluebuttonRecording.should_receive(:sync_additional_data)
        .with(anything, data)
      BigbluebuttonRecording.send(:create_recording, new_server, data)
      @recording = BigbluebuttonRecording.last
    }
    it("sets recordid") { @recording.recordid.should == recordid }
    it("sets meetingid") { @recording.meetingid.should == attrs[:meetingid] }
    it("sets name") { @recording.name.should == attrs[:name] }
    it("sets published") { @recording.published.should == attrs[:published] }
    it("sets end_time") { @recording.end_time.utc.to_i.should == attrs[:end_time].utc.to_i }
    it("sets start_time") { @recording.start_time.utc.to_i.should == attrs[:start_time].utc.to_i }
    it("sets server") { @recording.server.should == new_server }
    it("sets room") { @recording.room.should == @room }
    it("sets meeting") { @recording.meeting.should == @meeting }
    it("sets description") {
      time = data[:start_time].utc.to_formatted_s(:long)
      @recording.description.should == I18n.t('bigbluebutton_rails.recordings.default.description', :time => time)
    }
  end

  describe ".adapt_recording_hash" do
    let(:before) {
      { :recordID => "anything",
        :meetingID => "anything",
        :name => "anything",
        :published => "anything",
        :startTime => "anything",
        :endTime => "anything"
      }
    }
    let(:after) {
      { :recordid => "anything",
        :meetingid => "anything",
        :name => "anything",
        :published => "anything",
        :start_time => "anything",
        :end_time => "anything"
      }
    }
    subject { BigbluebuttonRecording.send(:adapt_recording_hash, before) }
    it { should eq(after) }
  end

  describe ".sync_additional_data" do
    let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }
    let(:data) {
      {
        :recordID => attrs[:recordid],
        :meetingID => attrs[:meetingid],
        :name => attrs[:name],
        :published => attrs[:published],
        :startTime => attrs[:start_time],
        :endTime => attrs[:end_time],
        :metadata => { :any => "any" },
        :playback => { :format => [ { :type => "any1" }, { :type => "any2" } ] }
      }
    }

    it "succeds" do
      BigbluebuttonRecording.should_receive(:sync_metadata)
        .with(recording, data[:metadata])
      BigbluebuttonRecording.should_receive(:sync_playback_formats)
        .with(recording, data[:playback][:format])
      BigbluebuttonRecording.send(:sync_additional_data, recording, data)
    end

    it "doesn't update metadata if there's no metadata info" do
      BigbluebuttonRecording.should_receive(:sync_playback_formats)
      BigbluebuttonRecording.should_not_receive(:sync_metadata)
      BigbluebuttonRecording.send(:sync_additional_data, recording, data.except(:metadata))
    end

    it "doesn't update playback formats if there's no :playback key" do
      BigbluebuttonRecording.should_receive(:sync_metadata)
      BigbluebuttonRecording.should_not_receive(:sync_playback_formats)
      BigbluebuttonRecording.send(:sync_additional_data, recording, data.except(:playback))
    end

    it "doesn't update playback formats if there's no :format key" do
      BigbluebuttonRecording.should_receive(:sync_metadata)
      BigbluebuttonRecording.should_not_receive(:sync_playback_formats)
      new_data = data.clone
      new_data[:playback].delete(:format)
      BigbluebuttonRecording.send(:sync_additional_data, recording, new_data)
    end
  end

  describe ".sync_metadata" do
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

    context "updates metadata that are already in the db" do
      let(:metadata) {
        { :course => "Fundamentals of JAVA",
          :description => "List of recordings"
        }
      }
      before {
        # two metadata to be updated
        @meta1 = FactoryGirl.create(:bigbluebutton_metadata,
                                    :owner => recording, :name => "course")
        @meta2 = FactoryGirl.create(:bigbluebutton_metadata,
                                    :owner => recording, :name => "description")
        BigbluebuttonRecording.send(:sync_metadata, recording, metadata)
      }
      it { BigbluebuttonMetadata.count.should == 2 }
      it { recording.metadata.count.should == 2 }
      it { BigbluebuttonMetadata.find_by_name(:course).content.should == metadata[:course] }
      it { BigbluebuttonMetadata.find_by_name(:course).id.should == @meta1.id }
      it { BigbluebuttonMetadata.find_by_name(:description).content.should == metadata[:description] }
      it { BigbluebuttonMetadata.find_by_name(:description).id.should == @meta2.id }
    end

    context "updates metadata from the db if not in the parameters" do
      let(:metadata) {
        { :course => "Fundamentals of JAVA" }
      }
      before {
        # two metadata to be removed
        FactoryGirl.create(:bigbluebutton_metadata,
                           :owner => recording, :name => "meta1deleted")
        FactoryGirl.create(:bigbluebutton_metadata,
                           :owner => recording, :name => "meta2deleted")
        BigbluebuttonRecording.send(:sync_metadata, recording, metadata)
      }
      it { recording.metadata.count.should == 1 }
      it { BigbluebuttonMetadata.find_by_name(:course).content.should == metadata[:course] }
      it { BigbluebuttonMetadata.find_by_name(:meta1deleted).should be_nil }
      it { BigbluebuttonMetadata.find_by_name(:meta2deleted).should be_nil }
    end

    context "creates metadata that's not in the db yet" do
      let(:metadata) {
        { :course => "Fundamentals of JAVA",
          :description => "List of recordings"
        }
      }
      before {
        BigbluebuttonRecording.send(:sync_metadata, recording, metadata)
      }
      it { recording.metadata.count.should == 2 }
      it { BigbluebuttonMetadata.find_by_name(:course).content.should == metadata[:course] }
      it { BigbluebuttonMetadata.find_by_name(:description).content.should == metadata[:description] }
    end

  end

  describe ".sync_playback_formats" do
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

    context "with several formats" do
      let(:data) {
        [ { :type => "any1", :url => "url1", :length => 1 },
          { :type => "any2", :url => "url2", :length => 2 } ]
      }
      before {
        # one playback format to be updated
        FactoryGirl.create(:bigbluebutton_playback_format,
                           :recording => recording, :format_type => "any1")
        # one to be deleted
        FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording)

        BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
      }
      it { BigbluebuttonPlaybackFormat.count.should == 2 }
      it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).count.should == 2 }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any1").url.should == "url1" }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any1").length.should == 1 }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any2").url.should == "url2" }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any2").length.should == 2 }
    end

    context "with a single format" do
      let(:data) {
        { :type => "any1", :url => "url1", :length => 1 }
      }
      before {
        # one playback format to be updated
        FactoryGirl.create(:bigbluebutton_playback_format,
                           :recording => recording, :format_type => "any1")
        # one to be deleted
        FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording)

        BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
      }
      it { BigbluebuttonPlaybackFormat.count.should == 1 }
      it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).count.should == 1 }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any1").url.should == "url1" }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any1").length.should == 1 }
    end

    context "ignores formats with blank type" do
      let(:data) {
        { :url => "url1", :length => 1 }
        { :type => "", :url => "url1", :length => 1 }
        { :type => "any", :url => "url2", :length => 1 }
      }
      before {
        BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
      }
      it { BigbluebuttonPlaybackFormat.count.should == 1 }
      it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).count.should == 1 }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any").url.should == "url2" }
      it { BigbluebuttonPlaybackFormat.find_by_format_type("any").length.should == 1 }
    end

  end

  describe ".find_matching_meeting" do

    context "if no recording is informed" do
      let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :room => nil) }
      subject { BigbluebuttonRecording.send(:find_matching_meeting, nil) }
      it { subject.should be_nil }
    end

    context "if the recording has no room associated to it" do
      let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :room => nil) }
      subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
      it { subject.should be_nil }
    end

    context "if can't find the start time in recordid" do
      let(:recording) { FactoryGirl.create(:bigbluebutton_recording, :recordid => "without-timestamp") }
      subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
      it { subject.should be_nil }
    end

    context "if found a start time in recordid" do
      let(:meeting_start_time) { DateTime.now }
      let(:recording) {
        FactoryGirl.create(:bigbluebutton_recording, :recordid => "#{SecureRandom.uuid}-#{meeting_start_time.to_i}")
      }

      context "when there's no associated meeting" do
        subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
        it { subject.should be_nil }
      end

      context "when there's one associated meeting" do
        before {
          @meeting = FactoryGirl.create(:bigbluebutton_meeting, :room => recording.room, :start_time => meeting_start_time)
        }
        subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
        it { subject.should eq(@meeting) }
      end
    end

  end

end
