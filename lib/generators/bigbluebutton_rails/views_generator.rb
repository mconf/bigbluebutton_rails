require 'rails/generators/active_record'

module BigbluebuttonRails
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../app/views", __FILE__)
      desc "Copies all bigbluebutton_rails views into your application folders."

      argument :scope, :required => false, :default => nil,
                       :desc => "The scope to copy views to"

      def copy_views
        directory "bigbluebutton", "app/views/#{ scope || :bigbluebutton}"
      end

    end
  end
end
