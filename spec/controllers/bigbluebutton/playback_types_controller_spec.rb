require 'spec_helper'

describe Bigbluebutton::PlaybackTypesController do
  render_views
  let!(:playback_type) { FactoryGirl.create(:bigbluebutton_playback_type) }

  describe "#update" do
    let!(:new_playback_type) { FactoryGirl.build(:bigbluebutton_playback_type, visible: !playback_type.visible) }
    let(:referer) { "/back" }
    before { request.env["HTTP_REFERER"] = referer }

    context "on success" do
      before(:each) {
        expect {
          put :update, :id => playback_type.to_param, :bigbluebutton_playback_type => new_playback_type.attributes
        }.not_to change{ BigbluebuttonPlaybackType.count }
      }
      it { should respond_with(:redirect) }
      it { should redirect_to(referer) }
      it {
        saved = BigbluebuttonPlaybackType.find(playback_type)
        saved.should have_same_attributes_as(new_playback_type, ['identifier'])
      }
      it { should set_the_flash.to(I18n.t('bigbluebutton_rails.playback_types.notice.update.success')) }
    end

    context "on failure" do
      before(:each) {
        BigbluebuttonPlaybackType.should_receive(:find).and_return(playback_type)
        playback_type.should_receive(:update_attributes).and_return(false)
        playback_type.errors.add :identifier, "first"
        playback_type.errors.add :visible, "second"
        put :update, :id => playback_type.to_param, :bigbluebutton_playback_type => new_playback_type.attributes
      }
      it { should respond_with(:redirect) }
      it { should redirect_to(referer) }
      it {
        expected = "Identifier first, Visible second"
        should set_the_flash.to(expected)
      }
    end

    describe "params handling" do
      let(:attrs) { FactoryGirl.attributes_for(:bigbluebutton_playback_type) }
      let(:params) { { :bigbluebutton_playback_type => attrs } }
      let(:allowed_params) {
        [ :visible, :default ]
      }
      it {
        # we just check that the rails method 'permit' is being called on the hash with the
        # correct parameters
        BigbluebuttonPlaybackType.stub(:find).and_return(playback_type)
        playback_type.stub(:update_attributes).and_return(true)
        attrs.stub(:permit).and_return(attrs)
        controller.stub(:params).and_return(params)

        put :update, :id => playback_type.to_param, :bigbluebutton_playback_type => new_playback_type.attributes
        attrs.should have_received(:permit).with(*allowed_params)
      }
    end

    context "doesn't override @playback_type" do
      let!(:other_playback_type) { FactoryGirl.create(:bigbluebutton_playback_type) }
      let(:format) { FactoryGirl.create(:bigbluebutton_playback_format, :playback_type => playback_type) }
      before { controller.instance_variable_set(:@playback_type, other_playback_type) }
      before(:each) {
        put :update, :id => playback_type.to_param, :bigbluebutton_playback_type => new_playback_type.attributes
      }
      it { should assign_to(:playback_type).with(other_playback_type) }
    end
  end

  # important because it might break custom actions on controllers that inherit from this
  skip "doesn't call #find_playback_type for custom actions"

end
