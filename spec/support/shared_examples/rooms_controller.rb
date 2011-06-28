# Checks calls to RoomsController.join_internal method when the user
# is an ATTENDEE (it can be the role of the current user or can be defined
# by the password the user typed)
shared_examples_for "internal join caller (attendee)" do
  context "when the conference is running" do
    before {
      mocked_api.should_receive(:is_meeting_running?).and_return(true)
      mocked_api.should_receive(:join_meeting_url).
        with(room.meetingid, anything, room.attendee_password).
        and_return("http://test.com/attendee/join")
    }
    before(:each) { request }

    it { should assign_to(:server).with(mocked_server) }
    it "redirects to the attendee join url" do
      should respond_with(:redirect)
      should redirect_to("http://test.com/attendee/join")
    end
  end

  context "when the conference is NOT running" do
    before { mocked_api.should_receive(:is_meeting_running?).and_return(false) }

    it "do not try to create the conference" do
      mocked_api.should_not_receive(:create_meeting)
      request
    end

    it "renders #invite" do
      request
      should respond_with(:success)
      should render_template(template)
      should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.not_running'))
    end
  end
end

# Same as "internal join caller (attendee), but for the MODERATOR role
shared_examples_for "internal join caller (moderator)" do
  before {
    mocked_api.should_receive(:join_meeting_url).
      with(room.meetingid, anything, room.moderator_password).
      and_return("http://test.com/mod/join")
  }

  context "when the conference is running" do
    before { mocked_api.should_receive(:is_meeting_running?).and_return(true) }
    before(:each) { request }

    it { should assign_to(:server).with(mocked_server) }

    it "redirects to the moderator join url" do
      should respond_with(:redirect)
      should redirect_to("http://test.com/mod/join")
    end
  end

  context "when the conference is NOT running" do
    before { mocked_api.should_receive(:is_meeting_running?).and_return(false) }

    it "creates the conference" do
      mocked_api.should_receive(:create_meeting).
        with(room.name, room.meetingid, room.moderator_password,
             room.attendee_password, room.welcome_msg, room.dial_number,
             room.logout_url, room.max_participants, room.voice_bridge)
      request
    end

    context "adds the protocol/domain to logout_url" do
      after(:each) { request }

      it "when it doesn't specify neither a protocol or domain" do
        room.update_attributes(:logout_url => "/incomplete/url")
        full_logout_url = "http://test.host" + room.logout_url

        mocked_api.should_receive(:create_meeting).
          with(anything, anything, anything, anything, anything, anything,
               full_logout_url, anything, anything)
      end

      it "when it doesn't specify the protocol" do
        room.update_attributes(:logout_url => "www.host.com/incomplete/url")
        full_logout_url = "http://" + room.logout_url

        mocked_api.should_receive(:create_meeting).
          with(anything, anything, anything, anything, anything, anything,
               full_logout_url, anything, anything)
      end

      it "but not when it has a protocol already defined" do
        room.update_attributes(:logout_url => "http://with/protocol")
        mocked_api.should_receive(:create_meeting).
          with(anything, anything, anything, anything, anything, anything,
               room.logout_url, anything, anything)
      end
    end

  end

end



