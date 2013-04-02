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
    it { should validate_format_of(:name).not_with("a b").with_message(msg) }
    it { should validate_format_of(:name).not_with("1a").with_message(msg) }
    it { should validate_format_of(:name).not_with("").with_message(msg) }
    it { should validate_format_of(:name).not_with("ab@c").with_message(msg) }
    it { should validate_format_of(:name).not_with("ab#c").with_message(msg) }
    it { should validate_format_of(:name).not_with("ab$c").with_message(msg) }
    it { should validate_format_of(:name).not_with("ab%c").with_message(msg) }
    it { should validate_format_of(:name).not_with("ábcd").with_message(msg) }
    it { should validate_format_of(:name).not_with("-abc").with_message(msg) }
    it { should validate_format_of(:name).not_with("_abc").with_message(msg) }
    it { should validate_format_of(:name).not_with("abc_").with_message(msg) }
    it { should validate_format_of(:name).not_with("abc-123_d5").with_message(msg) }
    it { should validate_format_of(:name).with("abc-") }
    it { should validate_format_of(:name).with("abc-0") }
    it { should validate_format_of(:name).with("abc") }
    it { should validate_format_of(:name).with("aBcD") }
    it { should validate_format_of(:name).with("abc123") }
    it { should validate_format_of(:name).with("abc-123-d5") }
  end

  it { should_not validate_presence_of(:content) }

  [:name, :content].each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end

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
