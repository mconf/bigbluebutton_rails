require 'rails/generators/active_record'

module BigbluebuttonRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      desc "Creates the initializer, initial migration and locale files."

      def copy_locale
        copy_file "../../../../config/locales/en.yml", "config/locales/bigbluebutton_rails.en.yml"
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        migration_template 'migration.rb', 'db/migrate/create_bigbluebutton_rails.rb'
      end

    end
  end
end
