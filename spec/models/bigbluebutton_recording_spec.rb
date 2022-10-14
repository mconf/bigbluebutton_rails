# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonRecording do
  it "loaded correctly" do
    BigbluebuttonRecording.new.should be_a_kind_of(ActiveRecord::Base)
  end

  it { should belong_to(:room) }

  it { should belong_to(:meeting) }

  it { should validate_presence_of(:recordid) }
  it { should validate_uniqueness_of(:recordid) }

  it { should have_many(:metadata).dependent(:destroy) }

  it { should have_many(:playback_formats).dependent(:destroy) }

  describe "#size" do
    # make sure it's a bigint
    it { should allow_value(-9223372036854775808).for(:size) }
    it { should allow_value(0).for(:size) }
    it { should allow_value(9223372036854775807).for(:size) }
  end

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

  describe "#get_token" do
    it { should respond_to(:get_token) }

    let!(:recording) { FactoryGirl.create(:bigbluebutton_recording) }
    let!(:type_default) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
    let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let(:user) { FactoryGirl.build(:user) }
    let(:user_ip) { "10.0.0.1" }
    let(:api) { double(BigBlueButton::BigBlueButtonApi) }

    before do
      BigbluebuttonServer.any_instance.stub(:api).and_return(api)
      api.stub(:send_api_request).and_return({:returncode=>true, :token=>"RECORDING_TOKEN", :messageKey=>"", :message=>""})
    end

    it  { recording.get_token(user, user_ip).should include("RECORDING_TOKEN") }
  end

  describe "#server" do
    it { should respond_to(:server) }

    let!(:room) { FactoryGirl.create(:bigbluebutton_room) }
    let!(:recording) { FactoryGirl.create(:bigbluebutton_recording, room: room) }
    let!(:server) { FactoryGirl.create(:bigbluebutton_server) }

    before do
      BigbluebuttonRoom.any_instance.stub(:server).and_return(server)
    end

    it  { recording.server.should eql(server) }
  end

  describe "#token_url" do
    it { should respond_to(:token_url) }

    let!(:recording) { FactoryGirl.create(:bigbluebutton_recording) }
    let!(:type_default) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
    let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
    let(:user) { FactoryGirl.build(:user) }
    let(:user_ip) { "10.0.0.1" }
    let!(:format) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording, playback_type: type_default) }
    let(:api) { double(BigBlueButton::BigBlueButtonApi) }

    before do
      BigbluebuttonServer.any_instance.stub(:api).and_return(api)
      api.stub(:send_api_request).and_return({:returncode=>true, :token=>"RECORDING_TOKEN", :messageKey=>"", :message=>""})
    end

    it  { recording.token_url(user, user_ip, format).should include("?token=RECORDING_TOKEN") }
  end

  describe "#default_playback_format" do
    let!(:recording) { FactoryGirl.create(:bigbluebutton_recording) }
    let!(:type_default) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
    let!(:type_other) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
    let!(:format1) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording, playback_type: type_other) }
    let!(:format2) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording, playback_type: type_default) }
    let!(:format3) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording, playback_type: type_other) }

    context "in a normal situation" do
      it { recording.default_playback_format.should eql(format2) }
    end

    context "when there's more than one format of the default type" do
      let!(:format4) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording, playback_type: type_default) }
      it { recording.default_playback_format.should eql(format2) }
    end
  end

  describe "#delete_from_server" do
    let!(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

    context "when there's a server" do
      let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
      before {
        recording.should_receive(:server).and_return(server)
        server.should_receive(:send_delete_recordings).with(recording.recordid).and_return('response')
      }
      it { recording.delete_from_server!.should eql('response') }
    end

    context "when there is no server" do
      before {
        recording.should_receive(:server).and_return(nil)
      }
      it { recording.delete_from_server!.should be(false) }
    end
  end

  describe ".overall_average_length" do
    context "when there's no recording" do
      it { BigbluebuttonRecording.overall_average_length.should eql(0) }
    end

    context "when there are a few recordings" do
      let!(:recording1) { FactoryGirl.create(:bigbluebutton_recording) }
      let!(:recording2) { FactoryGirl.create(:bigbluebutton_recording) }
      let!(:type_default) { FactoryGirl.create(:bigbluebutton_playback_type, default: true) }
      let!(:type_other) { FactoryGirl.create(:bigbluebutton_playback_type, default: false) }
      let!(:format_other_rec1) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording1, playback_type: type_other, length: 50) }
      let!(:format_default_rec1) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording1, playback_type: type_default, length: 100) }
      let!(:format_other_rec2) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording2, playback_type: type_other, length: 50) }
      let!(:format_default_rec2) { FactoryGirl.create(:bigbluebutton_playback_format, recording: recording2, playback_type: type_default, length: 100) }

      it { BigbluebuttonRecording.overall_average_length.should eql(6000.0) }
    end
  end

  describe ".overall_average_size" do
    context "when there's no recording" do
      it { BigbluebuttonRecording.overall_average_size.should eql(0) }
    end

    context "when there are a few recordings" do
      let!(:recording1) { FactoryGirl.create(:bigbluebutton_recording, size: 100000000) } # 100 MB
      let!(:recording2) { FactoryGirl.create(:bigbluebutton_recording, size: 200000000) } # 200 MB

      it { BigbluebuttonRecording.overall_average_size.should eql(150000000) }
    end
  end

  describe ".recording_changed?" do
    let!(:data) {
      {
        recordid: "recording-1",
        meetingid: "meetingid-1",
        name: "Evening Class1",
        published: true,
        start_time: DateTime.now,
        end_time: DateTime.now + 2.hours,
        size: "100",
        state: "processing",
        metadata: {
          course: "Fundamentals of JAVA",
          description: "List of recordings",
          activity: "Evening Class1"
        },
        playback: { format:
          [
           { type: "slides",
             url: "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
             length: 64
           },
           { type: "presentation",
             url: "http://test-install.blindsidenetworks.com/presentation/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
             length: 64
           }
          ]
        }
      }
    }
    let!(:recording) {
      attrs = {
        recordid: data[:recordid],
        meetingid: data[:meetingid],
        name: data[:name],
        published: data[:published],
        start_time: data[:start_time],
        end_time: data[:end_time],
        size: data[:size],
        state: data[:state],
      }
      r = FactoryGirl.create(:bigbluebutton_recording, attrs)
      data[:metadata].each do |k, v|
        BigbluebuttonMetadata.create(owner: r, name: k, content: v)
      end
      data[:playback][:format].each do |format|
        type = BigbluebuttonPlaybackType.create(visible: true, identifier: format[:type])
        BigbluebuttonPlaybackFormat.create(recording: r, url: format[:url], length: format[:length], playback_type: type)
      end
      r
    }

    it "returns false when they didn't changed" do
      BigbluebuttonRecording.recording_changed?(recording, data).should be(false)
    end

    tracked_attrs = [
      [ :end_time, :time ],
      [ :start_time, :time ],
      [ :meetingid, :string ],
      [ :recordid, :string ],
      [ :name, :string ],
      [ :state, :string ],
      [ :published, :boolean ],
      [ :size, :string ]
    ]
    tracked_attrs.each do |attr|
      context "returns true when the attribute #{attr[0]} changed" do
        it "in the data" do
          data[attr[0]] = case attr[1]
                          when :time
                            data[attr[0]] + 1.day
                          when :string
                            data[attr[0]] + "1"
                          when :boolean
                            !data[attr[0]]
                          end
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end

        it "in the database" do
          case attr[1]
          when :time
            recording.update_attribute(attr[0], data[attr[0]] + 1.day)
          when :string
            recording.update_attribute(attr[0], data[attr[0]] + "1")
          when :boolean
            recording.update_attribute(attr[0], !data[attr[0]])
          end
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end
      end
    end

    context "returns true when a metadata" do
      context "changed" do
        it "in the data" do
          data[:metadata][:course] = data[:metadata][:course] + "-changed"
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end

        it "in the database" do
          recording.metadata.first.update(content: recording.metadata.first.content + "-changed")
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end
      end

      context "was added" do
        it "in the data" do
          data[:metadata][:new_one] = "anything"
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end

        it "in the database" do
          BigbluebuttonMetadata.create(owner: recording, name: "new", content: "anything")
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end
      end

      context "was removed" do
        it "in the data" do
          data[:metadata].delete(:course)
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end

        it "in the database" do
          recording.metadata.first.destroy
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end
      end
    end

    context "returns true when a playback format" do
      context "changed" do
        it "in the data" do
          data[:playback][:format][0][:url] = data[:playback][:format][0][:url] + "/changed"
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end

        it "in the database" do
          recording.playback_formats.first.update(url: recording.playback_formats.first.url + "/changed")
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end
      end

      context "was added" do
        it "in the data" do
          data[:playback][:format] << {
            type: "new-format",
            url: "http://anything.here",
            length: 64
          }
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end

        it "in the database" do
          type = BigbluebuttonPlaybackType.create(visible: true, identifier: "new-format-db")
          BigbluebuttonPlaybackFormat.create(recording: recording, url: "anything", length: 12, playback_type: type)
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end
      end

      context "was removed" do
        it "in the data" do
          data[:playback][:format] = data[:playback][:format].drop(1)
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end

        it "in the database" do
          recording.playback_formats.first.destroy
          BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
        end
      end
    end

    context "ignores ignored keys" do
      it "in the data" do
        data[:random] = "anything"
        BigbluebuttonRecording.recording_changed?(recording, data).should be(false)
      end

      it "in the database" do
        recording.available = !recording.available
        BigbluebuttonRecording.recording_changed?(recording, data).should be(false)
      end
    end

    it "ignores the ordering of the elements in the inputs" do
      data[:playback][:format] = data[:playback][:format].reverse
      BigbluebuttonRecording.recording_changed?(recording, data).should be(false)
    end

    context "works when there are no formats" do
      it "in the data" do
        data[:playback].delete(:format)
        BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
      end

      it "in the database" do
        BigbluebuttonPlaybackFormat.delete_all
        BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
      end
    end

    context "works when there is no metadata" do
      it "in the data" do
        data.delete(:metadata)
        BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
      end

      it "in the database" do
        BigbluebuttonMetadata.delete_all
        BigbluebuttonRecording.recording_changed?(recording, data).should be(true)
      end
    end
  end

  describe ".sync" do
    let(:data) {
      [{
        recordID: "recording-1",
        meetingID: "meetingid-1",
        name: "Evening Class1",
        published: true,
        startTime: DateTime.now,
        endTime: DateTime.now + 2.hours,
        size: 100,
        state: 'processing',
        metadata: {
          course: "Fundamentals of JAVA",
          description: "List of recordings",
          activity: "Evening Class1"
        },
        playback: { format:
         [{ type: "slides",
            url: "http://test-install.blindsidenetworks.com/playback/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
            length: 64
          },
          { type: "presentation",
            url: "http://test-install.blindsidenetworks.com/presentation/slides/playback.html?meetingId=125468758b24fa27551e7a065849dda3ce65dd32-1329872486268",
            length: 64
          }]
        }
      }]
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
      it { @recording.end_time.to_i.should == data[0][:endTime].to_i }
      it { @recording.start_time.to_i.should == data[0][:startTime].to_i }
      it { @recording.server.should == new_server }
      it { @recording.room.should == @room }
      it { @recording.available.should == true }
      it { @recording.size.should == 100 }
      it { @recording.metadata.count.should == 3 }
      3.times do |i|
        it { @recording.metadata.order(:name)[i].name.should == data[0][:metadata].keys.sort[i].to_s }
        it { @recording.metadata.order(:content)[i].content.should == data[0][:metadata].values.sort[i] }
      end
      it { @recording.playback_formats.count.should == 2 }
      2.times do |i|
        it { @recording.playback_formats[i].playback_type.identifier.should == data[0][:playback][:format][i][:type] }
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
      it { @recording.end_time.to_i.should == data[0][:endTime].to_i }
      it { @recording.start_time.to_i.should == data[0][:startTime].to_i }
      it { @recording.server.should == new_server }
      it { @recording.room.should == @room }
      it { @recording.available.should == true }
      it { @recording.size.should == 100 }
      it { @recording.metadata.count.should == 3 }
      3.times do |i|
        it { @recording.metadata.order(:name)[i].name.should == data[0][:metadata].keys.sort[i].to_s }
        it { @recording.metadata.order(:content)[i].content.should == data[0][:metadata].values.sort[i] }
      end
      it { @recording.playback_formats.count.should == 2 }
      2.times do |i|
        it { @recording.playback_formats[i].playback_type.identifier.should == data[0][:playback][:format][i][:type] }
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
      context "for recordings in multiple servers" do
        before {
          BigbluebuttonRecording.delete_all
          @r1 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          @r2 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          @r3 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          @r4 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          scope_server_recordings = BigbluebuttonRecording.where(id: [@r1, @r2].map(&:id))
          BigbluebuttonRecording.sync(new_server, data, scope_server_recordings)
        }
        it { BigbluebuttonRecording.count.should == 5 }
        it ("recording from the target server") { @r1.reload.available.should == false }
        it ("recording from the target server") { @r2.reload.available.should == false }
        it ("recording from another server") { @r3.reload.available.should == true }
        it ("recording from another server") { @r4.reload.available.should == true }
      end

      context "when there are no recordings in the target server" do
        before {
          @r1 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          @r2 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          scope_server_recordings = BigbluebuttonRecording.where(id: [].map(&:id))
          BigbluebuttonRecording.sync(new_server, data, scope_server_recordings)
        }
        it ("recording from another server") { @r1.reload.available.should == true }
        it ("recording from another server") { @r2.reload.available.should == true }
      end

      context "when there are no recordings in other servers" do
        before {
          BigbluebuttonRecording.delete_all
          @r1 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          @r2 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
          scope_server_recordings = BigbluebuttonRecording.where(id: [@r1, @r2].map(&:id))
          BigbluebuttonRecording.sync(new_server, data, scope_server_recordings)
        }
        it { BigbluebuttonRecording.count.should == 3 }
        it ("recording from another server") { @r1.reload.available.should == false }
        it ("recording from another server") { @r2.reload.available.should == false }
      end

      context "when updating for a single room" do
        let(:target_room) { FactoryGirl.create(:bigbluebutton_room) }
        before {
          BigbluebuttonRecording.delete_all
          @r1 = FactoryGirl.create(:bigbluebutton_recording, :available => true, :room => target_room)
          @r2 = FactoryGirl.create(:bigbluebutton_recording, :available => true, :room => target_room)
          @r3 = FactoryGirl.create(:bigbluebutton_recording, :available => true, :room => FactoryGirl.create(:bigbluebutton_room))
          @r4 = FactoryGirl.create(:bigbluebutton_recording, :available => true, :room => FactoryGirl.create(:bigbluebutton_room))
          BigbluebuttonRecording.sync(new_server, data, BigbluebuttonRecording.where(room: target_room))
        }
        it ("recording from the target server") { @r1.reload.available.should == false }
        it ("recording from the target server") { @r2.reload.available.should == false }
        it ("recording from another server") { @r3.reload.available.should == true }
        it ("recording from another server") { @r4.reload.available.should == true }
      end

      context "only changes 'available' for recordings created before the sync started" do
        before {
          sync_started_at = DateTime.now

          BigbluebuttonRecording.delete_all
          @r1 = FactoryGirl.create(:bigbluebutton_recording, :available => true, created_at: sync_started_at + 1.hour)
          @r2 = FactoryGirl.create(:bigbluebutton_recording, :available => true, created_at: sync_started_at + 1.second)
          @r3 = FactoryGirl.create(:bigbluebutton_recording, :available => true, created_at: sync_started_at)
          @r4 = FactoryGirl.create(:bigbluebutton_recording, :available => true, created_at: sync_started_at - 1.second)
          scope = BigbluebuttonRecording.where(id: [@r1, @r2, @r3, @r4].map(&:id))

          BigbluebuttonRecording.sync(new_server, data, scope, sync_started_at)
        }
        it { BigbluebuttonRecording.count.should == 5 }
        it ("recording created after the sync started") { @r1.reload.available.should == true }
        it ("recording created after the sync started") { @r2.reload.available.should == true }
        it ("recording created before the sync started") { @r3.reload.available.should == false }
        it ("recording created before the sync started") { @r4.reload.available.should == false }
      end
    end

    context "sets recording that are in the parameters as available in a full sync" do
      before {
        BigbluebuttonRecording.delete_all
        @r = FactoryGirl.create(:bigbluebutton_recording, :available => false, :recordid => data[0][:recordID])
        # so it creates the recording the first time
        scope = BigbluebuttonRecording.where(id: [@r].map(&:id))
        BigbluebuttonRecording.sync(new_server, data, scope)

        BigbluebuttonRecording.find_by(recordid: data[0][:recordID])
          .update_attributes(available: false)

        BigbluebuttonRecording.sync(new_server, data, scope)
      }
      it { @r.reload.available.should be(true) }
    end

    context "doesn't set recordings that are not in the parameters as unavailable if not in a full sync" do
      before {
        BigbluebuttonRecording.delete_all
        @r1 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
        @r2 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
        @r3 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
        @r4 = FactoryGirl.create(:bigbluebutton_recording, :available => true)
        BigbluebuttonRecording.sync(new_server, data)
      }
      it { @r1.reload.available.should == true }
      it { @r2.reload.available.should == true }
      it { @r3.reload.available.should == true }
      it { @r4.reload.available.should == true }
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

    context "when there are unused playback types on the database" do
      before {
        FactoryGirl.create(:bigbluebutton_playback_type, :identifier => "to-be-removed")
        FactoryGirl.create(:bigbluebutton_playback_type, :identifier => "another")
        BigbluebuttonRecording.sync(new_server, data)
      }
      it { BigbluebuttonPlaybackType.count.should == 2 }
      it { BigbluebuttonPlaybackType.find_by(identifier: "slides").should_not be_nil }
      it { BigbluebuttonPlaybackType.find_by(identifier: "presentation").should_not be_nil }
    end

    it "doesn't update if the recording didn't change" do
      # once to create the recording
      now = DateTime.now
      expected = now - 1.day
      Timecop.freeze(expected)
      rec_data = data.clone
      BigbluebuttonRecording.sync(new_server, rec_data)

      # bug to the current timestamp
      rec = BigbluebuttonRecording.first
      Timecop.freeze(now)

      # shouldn't change it
      BigbluebuttonRecording.sync(new_server, rec_data)
      rec.reload.updated_at.to_i.should eql(expected.to_i)

      Timecop.return
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
        :size => attrs[:size],
        :metadata => { :any => "any" },
        :recordingUsers => { :user => [{ :externalUserID => 1 }, { :externalUserID => 2 }] },
        :playback => { :format => [ { :type => "any1" }, { :type => "any2" } ] }
      }
    }
    let(:new_server) { FactoryGirl.create(:bigbluebutton_server) }

    context "default behavior" do
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
      it { recording.end_time.to_i.should == attrs[:end_time].to_i }
      it { recording.start_time.to_i.should == attrs[:start_time].to_i }
      it { recording.size.should == attrs[:size] }
      it { recording.server.should == new_server }
      it { recording.room.should == @room }
      it { recording.recording_users.should eql([1, 2]) }
    end

    context "works if the recording returned has no :size attribute" do
      before {
        data.delete(:size)
        recording.update_attributes(size: 0)
        BigbluebuttonRecording.send(:update_recording, new_server, recording, data)
      }
      it { recording.size.should == 0 }
    end

    context "works if the recording returned has no :recordingUsers attribute" do
      before {
        data.delete(:recordingUsers)
        BigbluebuttonRecording.send(:update_recording, new_server, recording, data)
      }
      it { recording.recording_users.should == [] }
    end

    context "creates a new meeting if recording has room_id and meetingid but no corresponding meeting" do
      before {
        # make sure the recording has a room_id
        @room = FactoryGirl.create(:bigbluebutton_room, :meetingid => attrs[:meetingid])
        recording.room = @room
        allow(BigbluebuttonRails.configuration.match_room_recording).to receive(:call).with(data).and_return(@room)

        BigbluebuttonRecording.send(:update_recording, new_server, recording, data)
      }
      it("sets meeting_id") { recording.meeting_id.should_not be_nil }
      it("sets meetingid") { recording.meetingid.should_not be_nil }
      it("sets meeting") { recording.meeting.should_not be_nil }
    end
  end

  describe ".create_recording" do
    let(:meeting_create_time) { DateTime.now.utc.to_i }
    let(:recordid) { "#{SecureRandom.uuid}-#{meeting_create_time.to_i}" }
    let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_recording) }
    let(:data) {
      {
        :recordid => recordid,
        :meetingid => attrs[:meetingid],
        :name => attrs[:name],
        :published => attrs[:published],
        :start_time => meeting_create_time,
        :end_time => attrs[:end_time],
        :metadata => { :any => "any" },
        :recordingUsers => { :user => [{ :externalUserID => 3 }, { :externalUserID => 4 }] },
        :playback => { :format => [ { :type => "any1" }, { :type => "any2" } ] }
      }
    }
    let(:new_server) { FactoryGirl.create(:bigbluebutton_server) }

    context "default behavior" do
      before {
        @room = FactoryGirl.create(:bigbluebutton_room, :meetingid => attrs[:meetingid])
        @meeting = FactoryGirl.create(:bigbluebutton_meeting, :room => @room, :create_time => meeting_create_time, :meetingid => attrs[:meetingid])

        BigbluebuttonRecording.should_receive(:sync_additional_data)
          .with(anything, data)
        BigbluebuttonRecording.send(:create_recording, new_server, data)
        @recording = BigbluebuttonRecording.last
      }
      it("sets recordid") { @recording.recordid.should == recordid }
      it("sets meetingid") { @recording.meetingid.should == attrs[:meetingid] }
      it("sets name") { @recording.name.should == attrs[:name] }
      it("sets published") { @recording.published.should == attrs[:published] }
      it("sets end_time") { @recording.end_time.to_i.should == attrs[:end_time].to_i }
      it("sets start_time") { @recording.start_time.to_i.should == meeting_create_time }
      it("sets server") { @recording.server.should == new_server }
      it("sets room") { @recording.room.should == @room }
      it("sets meeting") { @recording.meeting.should == @meeting }
      it("sets recording_users") { @recording.recording_users.should eql([3, 4]) }
    end

    context "creates a new meeting if no meeting is found for that recording" do
      before {
        @room = FactoryGirl.create(:bigbluebutton_room, :meetingid => attrs[:meetingid])
        allow(BigbluebuttonRails.configuration.match_room_recording).to receive(:call).with(data).and_return(@room)

        BigbluebuttonRecording.should_receive(:sync_additional_data)
          .with(anything, data)
        BigbluebuttonRecording.send(:create_recording, new_server, data)
        @recording = BigbluebuttonRecording.last
      }
      it("sets meeting_id") { expect(@recording.meeting_id).not_to be_nil }
      it("sets meetingid") { expect(@recording.meetingid).not_to be_nil }
      it("sets meeting") { expect(@recording.meeting).not_to be_nil }
    end
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

  describe ".adapt_recording_users" do
    context "with one user" do
      let(:original) {
        { :user => { :externalUserID => 1 } }
      }
      let(:expected) { [1] }
      it { BigbluebuttonRecording.send(:adapt_recording_users, original).should eql(expected) }
    end

    context "with several users" do
      let(:original) {
        { :user => [{ :externalUserID => 2 }, { :externalUserID => 1 }, { :externalUserID => 15 }] }
      }
      let(:expected) { [2, 1, 15] }
      it { BigbluebuttonRecording.send(:adapt_recording_users, original).should eql(expected) }
    end

    [nil, []].each do |arg|
      context "returns nil if the argument is #{arg.inspect}" do
        it { BigbluebuttonRecording.send(:adapt_recording_users, arg).should be_nil }
      end
    end
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

    it "succeeds" do
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

    context "with a single format" do
      let(:data) {
        { :type => "any1", :url => "url1", :length => 1 }
      }

      context "and it's not in the database yet" do
        context "if it is not a downloadable format" do
          before {
            BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
          }
          it { BigbluebuttonPlaybackFormat.count.should == 1 }
          it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).count.should == 1 }
          it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.url.should == "url1" }
          it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.length.should == 1 }
          it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.visible.should be(true) }
        end

        context "if it is a downloadable format" do
          after {
            @previous = BigbluebuttonRails.configuration.downloadable_playback_types
          }
          before {
            BigbluebuttonRails.configuration.downloadable_playback_types = ['any1']
            BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
            BigbluebuttonRails.configuration.downloadable_playback_types = @previous
          }
          it { BigbluebuttonPlaybackFormat.count.should == 1 }
          it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.downloadable.should be(true) }
        end
      end

      context "and it's already in the database" do
        before {
          # one playback format to be updated
          playback_type = FactoryGirl.create(:bigbluebutton_playback_type, identifier: "any1", visible: false)
          FactoryGirl.create(:bigbluebutton_playback_format,
                             :recording => recording, :playback_type => playback_type)

          BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
        }
        it { BigbluebuttonPlaybackFormat.count.should == 1 }
        it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).count.should == 1 }
        it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.url.should == "url1" }
        it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.length.should == 1 }
        it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.visible.should be(false) }
      end

      context "and there are unused formats in the database" do
        before {
          # formats to be deleted
          FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording)
          FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording)

          BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
        }
        it { BigbluebuttonPlaybackFormat.count.should == 1 }
        it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).count.should == 1 }
        it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.url.should == "url1" }
        it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).last.length.should == 1 }
      end
    end

    context "with several formats" do
      let(:data) {
        [ { :type => "any1", :url => "url1", :length => 1 },
          { :type => "any2", :url => "url2", :length => 2 },
          { :type => "any3", :url => "url3", :length => 3 } ]
      }
      let(:playback_type) {
        FactoryGirl.create(:bigbluebutton_playback_type, identifier: "any1", visible: true)
      }
      let(:playback_type_hidden) {
        FactoryGirl.create(:bigbluebutton_playback_type, identifier: "any2", visible: false)
      }
      before {
        # two playback formats to be updated
        FactoryGirl.create(:bigbluebutton_playback_format,
                           :recording => recording, :playback_type => playback_type)
        FactoryGirl.create(:bigbluebutton_playback_format,
                           :recording => recording, :playback_type => playback_type_hidden)
        # one to be deleted
        FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording)

        BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
      }
      it { BigbluebuttonPlaybackFormat.count.should == 3 }
      it { BigbluebuttonPlaybackFormat.where(recording_id: recording.id).count.should == 3 }
      it {
        q = BigbluebuttonPlaybackFormat.where(recording_id: recording.id, playback_type_id: playback_type.id, url: "url1")
        q.size.should == 1
        f = q.first
        f.should_not be_nil
        f.length.should == 1
        f.visible.should be(true)
      }
      it {
        q = BigbluebuttonPlaybackFormat.where(recording_id: recording.id, playback_type_id: playback_type_hidden.id, url: "url2")
        q.size.should == 1
        f = q.first
        f.should_not be_nil
        f.length.should == 2
        f.visible.should be(false)
      }
      it {
        q = BigbluebuttonPlaybackFormat.where(recording_id: recording.id, playback_type_id: BigbluebuttonPlaybackType.last.id, url: "url3")
        q.size.should == 1
        f = q.first
        f.should_not be_nil
        f.length.should == 3
      }
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
      it { BigbluebuttonPlaybackType.count.should == 1 }
      it { BigbluebuttonPlaybackFormat.count.should == 1 }
      it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id).count.should == 1 }
      it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id, :playback_type_id => BigbluebuttonPlaybackType.last.id).first.url.should == "url2" }
      it { BigbluebuttonPlaybackFormat.where(:recording_id => recording.id, :playback_type_id => BigbluebuttonPlaybackType.last.id).first.length.should == 1 }
    end

    context "manages the playback types" do
      let(:data) {
        { :type => "any1", :url => "url1", :length => 1 }
      }

      context "when the playback type is already on the database" do
        let!(:playback_type) {
          FactoryGirl.create(:bigbluebutton_playback_type, :identifier => "any1")
        }
        before {
          BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
        }
        it { BigbluebuttonPlaybackType.count.should == 1 }
        it { BigbluebuttonPlaybackType.last.should ==  playback_type }
      end

      context "when the playback type is not on the database" do
        before {
          BigbluebuttonRecording.send(:sync_playback_formats, recording, data)
        }
        it { BigbluebuttonPlaybackType.count.should == 1 }
        it { BigbluebuttonPlaybackType.last.identifier.should == "any1" }
        it { BigbluebuttonPlaybackType.last.playback_formats.should include(BigbluebuttonPlaybackFormat.last) }
      end
    end
  end

  describe ".cleanup_playback_types" do
    let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }

    context "when all playback types are in use" do
      before {
        @kept1 = FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording).playback_type
        @kept2 = FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording).playback_type

        BigbluebuttonRecording.send(:cleanup_playback_types)
      }
      it { BigbluebuttonPlaybackType.count.should == 2 }
      it { BigbluebuttonPlaybackType.all.should include(@kept1) }
      it { BigbluebuttonPlaybackType.all.should include(@kept2) }
    end

    context "when there are unused playback types" do
      before {
        @removed1 = FactoryGirl.create(:bigbluebutton_playback_type)
        @removed2 = FactoryGirl.create(:bigbluebutton_playback_type)
        @kept1 = FactoryGirl.create(:bigbluebutton_playback_format, :recording => recording).playback_type

        BigbluebuttonRecording.send(:cleanup_playback_types)
      }

      it { BigbluebuttonPlaybackType.count.should == 1 }
      it { BigbluebuttonPlaybackType.all.should include(@kept1) }
      it { BigbluebuttonPlaybackType.all.should_not include(@removed1) }
      it { BigbluebuttonPlaybackType.all.should_not include(@removed2) }
    end
  end

  describe ".find_matching_meeting" do

    context "if no recording is informed" do
      let(:recording) { FactoryGirl.create(:bigbluebutton_recording, room: nil) }
      subject { BigbluebuttonRecording.send(:find_matching_meeting, nil) }
      it { subject.should be_nil }
    end

    context "if the recording has no room associated to it" do
      let(:recording) { FactoryGirl.create(:bigbluebutton_recording, room: nil) }
      subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
      it { subject.should be_nil }
    end

    context "when there is a meeting with internal_meeting_id matching the rec's recordid" do
      let(:recording) { FactoryGirl.create(:bigbluebutton_recording) }
      before {
        @meeting = FactoryGirl.create(:bigbluebutton_meeting,
          room: recording.room,
          internal_meeting_id: recording.recordid
        )
      }
      subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
      it { expect(subject).to eql(@meeting) }
    end

    context "when there isn't a meeting with internal_meeting_id matching the rec's recordid" do
      context "and the recording has no start_time" do
        let(:recording) { FactoryGirl.create(:bigbluebutton_recording, start_time: nil) }
        subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
        it { subject.should be_nil }
      end

      context "and the recording has start_time" do
        let(:meeting_create_time) { DateTime.now.to_i }
        let(:meetingid_rand) { SecureRandom.uuid }
        let(:recording) do
          FactoryGirl.create(:bigbluebutton_recording,
            recordid: "#{SecureRandom.uuid}-#{meeting_create_time}",
            start_time: meeting_create_time,
            meetingid: "#{meetingid_rand}-#{meeting_create_time}"
          )
        end

        context "when there's no associated meeting" do
          let!(:server) { FactoryGirl.create(:bigbluebutton_server) }
          before do
            @meeting = BigbluebuttonMeeting.create_meeting_record_from_recording(recording)
          end
          subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
          it("creates a meeting for the recording") { subject.should eq(@meeting) }
        end

        context "when there's one associated meeting" do
          before do
            @meeting = FactoryGirl.create(:bigbluebutton_meeting,
              room: recording.room,
              create_time: meeting_create_time,
              meetingid: "#{meetingid_rand}-#{meeting_create_time}"
            )
          end
          subject { BigbluebuttonRecording.send(:find_matching_meeting, recording) }
          it { subject.should eq(@meeting) }
        end
      end
    end

  end

end
