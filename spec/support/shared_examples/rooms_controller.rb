# Checks calls to RoomsController.join_internal method when the user
# is an ATTENDEE (it can be the role of the current user or can be defined
# by the password the user typed)
#
# Arguments:
#   room      # the target BigbluebuttonRoom
#   request   # the request to be executed
#   template  # the template that should be rendered
#
# TODO: review if we really need this shared_example
shared_examples_for "internal join caller" do
  before {
    BigbluebuttonRoom.stub(:find_by_param).and_return(room)
    controller.stub(:bigbluebutton_role).and_return(:attendee)
  }

  context "when the user has permission to join" do
    before {
      room.should_receive(:perform_join).with(user.name, :attendee, controller.request).
      and_return("http://test.com/join/url")
    }
    before(:each) { request }
    it { should respond_with(:redirect) }
    it { should redirect_to("http://test.com/join/url") }
  end

  context "when the user doesn't have permission to join" do
    before {
      room.should_receive(:perform_join).with(user.name, :attendee, controller.request).
      and_return(nil)
    }
    before(:each) { request }
    it { should respond_with(:success) }
    it { should render_template(template) }
    it { should set_the_flash.to(I18n.t('bigbluebutton_rails.rooms.errors.auth.not_running')) }
  end
end
