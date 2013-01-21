# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonRecording do
  it "loaded correctly" do
    BigbluebuttonRecording.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should belong_to(:server) }
  it { should validate_presence_of(:server) }

  it { should belong_to(:room) }

  it { should validate_presence_of(:recordid) }
  it { should validate_uniqueness_of(:recordid) }

  [:recordid, :meetingid, :name, :published, :start_time,
   :end_time].each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end

  it { should have_many(:metadata).dependent(:destroy) }

  it { should have_many(:playback_formats).dependent(:destroy) }

  describe "#to_param" do
    it { should respond_to(:to_param) }
    it {
      s = FactoryGirl.create(:bigbluebutton_recording)
      s.to_param.should be(s.recordid)
    }
  end

  describe "#sync" do
    let(:data) {
      [
       {
         :recordID => "recordid-1",
         :meetingID => "meetindid-1",
         :name => "Evening Class1",
         :published => true,
         :startTime => DateTime.now,
         :endTime => DateTime.now + 2.hours,
         :metadata => { :course => "Fundamentals of JAVA",
           :description => "List of recordings",
           :activity => "Evening Class1" },
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
        clone[:playback] = { :format =>
          [
           { # without :type to trigger an exception
             :url => "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
             :length => 64
           },
           { :type => "presentation",
             :url => "http://test-install.blindsidenetworks.com/presentation/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
             :length => 64
           }
          ]
        }
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

  describe "#update_recording" do
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
  end

  describe "#create_recording" do
    let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
    let(:data) {
      {
        :recordid => attrs[:recordid],
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
      BigbluebuttonRecording.should_receive(:sync_additional_data)
        .with(anything, data)
      BigbluebuttonRecording.send(:create_recording, new_server, data)
      @recording = BigbluebuttonRecording.last
    }
    it { @recording.recordid.should == attrs[:recordid] }
    it { @recording.meetingid.should == attrs[:meetingid] }
    it { @recording.name.should == attrs[:name] }
    it { @recording.published.should == attrs[:published] }
    it { @recording.end_time.utc.to_i.should == attrs[:end_time].utc.to_i }
    it { @recording.start_time.utc.to_i.should == attrs[:start_time].utc.to_i }
    it { @recording.server.should == new_server }
  end

  describe "#adapt_recording_hash" do
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

  describe "#sync_additional_data" do
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

  describe "#sync_metadata" do
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }
    let(:metadata) {
      { :course => "Fundamentals of JAVA",
        :description => "List of recordings",
        :activity => "Evening Class1"
      }
    }
    before {
      # one metadata to be updated
      FactoryGirl.create(:bigbluebutton_metadata,
                         :recording => recording, :name => "course")
      # one to be deleted
      FactoryGirl.create(:bigbluebutton_metadata, :recording => recording)

      BigbluebuttonRecording.send(:sync_metadata, recording, metadata)
    }
    it { BigbluebuttonMetadata.count.should == 3 }
    it { BigbluebuttonMetadata.where(:recording_id => recording.id).count.should == 3 }
    it { BigbluebuttonMetadata.find_by_name(:course).content.should == metadata[:course] }
    it { BigbluebuttonMetadata.find_by_name(:description).content.should == metadata[:description] }
    it { BigbluebuttonMetadata.find_by_name(:activity).content.should == metadata[:activity] }
  end

  describe "#sync_playback_formats" do
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

    context "with a single formats" do
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

  end

end
