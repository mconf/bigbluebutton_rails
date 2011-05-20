module BigbluebuttonRails
  class Engine < ::Rails::Engine

    initializer 'bigbluebutton_rails.helper' do |app|
      ActionView::Base.send :include, BigbluebuttonRailsHelper
    end

    initializer "bigbluebutton_rails.controller_methods" do
      ActiveSupport.on_load(:action_controller) do
        include BigbluebuttonRails::ControllerMethods
      end
    end

  end
end
