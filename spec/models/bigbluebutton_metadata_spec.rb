# -*- coding: utf-8 -*-
require 'spec_helper'

describe BigbluebuttonMetadata do
  it "loaded correctly" do
    BigbluebuttonMetadata.new.should be_a_kind_of(ActiveRecord::Base)
  end

  before { FactoryGirl.create(:bigbluebutton_metadata) }

  it { should belong_to(:recording) }
  it { should validate_presence_of(:recording_id) }

  it { should validate_presence_of(:name) }

  it { should_not validate_presence_of(:content) }

  [:recording_id, :name, :content].each do |attribute|
    it { should allow_mass_assignment_of(attribute) }
  end
end
