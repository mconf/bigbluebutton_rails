module BigbluebuttonRails
  class Engine < ::Rails::Engine

    initializer 'bigbluebutton_rails.helper' do |app|
      Rails.application.config.after_initialize do
        ActionView::Base.send :include, BigbluebuttonRailsHelper
      end
    end

    initializer "bigbluebutton_rails.controller_methods" do
      ActiveSupport.on_load(:action_controller) do
        include BigbluebuttonRails::ControllerMethods
      end
    end

  end
end
