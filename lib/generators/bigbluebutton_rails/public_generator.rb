require 'rails/generators/active_record'

module BigbluebuttonRails
  module Generators
    class PublicGenerator < Rails::Generators::Base
      source_root File.expand_path("../templates/public", __FILE__)
      desc "Copies all bigbluebutton_rails public files (javascripts and images) to your application."

      def copy_files
        copy_file "javascripts/jquery.min.js", "public/javascripts/jquery.min.js"
        copy_file "images/loading.gif", "public/images/loading.gif"
      end

    end
  end
end
