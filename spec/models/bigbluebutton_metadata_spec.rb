# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonMetadata do
  it "loaded correctly" do
    BigbluebuttonMetadata.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_metadata) }

  it { should belong_to(:owner) }
  it { should validate_presence_of(:owner_id) }
  it { should validate_presence_of(:owner_type) }

  it { should validate_presence_of(:name) }
  it { should validate_uniqueness_of(:name).scoped_to([:owner_id, :owner_type]) }
  context "#name format" do
    let(:msg) { I18n.t('bigbluebutton_rails.metadata.errors.name_format') }
    it { should_not allow_value("a b").for(:name).with_message(msg) }
    it { should_not allow_value("1a").for(:name).with_message(msg) }
    it { should_not allow_value("").for(:name).with_message(msg) }
    it { should_not allow_value("ab@c").for(:name).with_message(msg) }
    it { should_not allow_value("ab#c").for(:name).with_message(msg) }
    it { should_not allow_value("ab$c").for(:name).with_message(msg) }
    it { should_not allow_value("ab%c").for(:name).with_message(msg) }
    it { should_not allow_value("ábcd").for(:name).with_message(msg) }
    it { should_not allow_value("-abc").for(:name).with_message(msg) }
    it { should_not allow_value("_abc").for(:name).with_message(msg) }
    it { should_not allow_value("abc_").for(:name).with_message(msg) }
    it { should_not allow_value("abc-123_d5").for(:name).with_message(msg) }
    it { should allow_value("abc-").for(:name) }
    it { should allow_value("abc-0").for(:name) }
    it { should allow_value("abc").for(:name) }
    it { should allow_value("aBcD").for(:name) }
    it { should allow_value("abc123").for(:name) }
    it { should allow_value("abc-123-d5").for(:name) }
  end

  it { should_not validate_presence_of(:content) }

  context "reserved metadata keys" do
    before(:each) { subject.owner = FactoryGirl.create(:bigbluebutton_room) }

    it { should ensure_exclusion_of(:name)
          .in_array(BigbluebuttonRails.metadata_invalid_keys.map(&:to_s)) }

    it "allows values to be added to the list of invalid metadata keys" do
      old = BigbluebuttonRails.metadata_invalid_keys.clone
      BigbluebuttonRails.metadata_invalid_keys.push("1")
      old.push("1")
      should ensure_exclusion_of(:name).in_array(old.map(&:to_s))
    end

    it "only invalidates if the metadata belongs to a room" do
      subject.owner = FactoryGirl.create(:bigbluebutton_recording)
      should_not ensure_exclusion_of(:name)
        .in_array(BigbluebuttonRails.metadata_invalid_keys.map(&:to_s))
    end
  end
end
