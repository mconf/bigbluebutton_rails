require 'rails/generators/active_record'

module BigbluebuttonRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      argument :migrate_to_version, :type => :string, :default => "", :description => "Generate migration to this version"
      class_option :locale, :type => :boolean, :default => true, :description => "Include locale file"
      source_root File.expand_path("../templates", __FILE__)

      desc "Creates the migrations and locale files. Also used to create migrations when updating the gem version."

      def copy_locale
        # uses bigbluebutton_rails/config to avoid using the local application en.yml
        copy_file "../../../../../bigbluebutton_rails/config/locales/en.yml", "config/locales/bigbluebutton_rails.en.yml" if options.locale?
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        if migrate_to_version.blank?
          migration_template 'migration.rb', 'db/migrate/create_bigbluebutton_rails.rb'
        else
          migration_template "migration_#{version_filename}.rb", "db/migrate/bigbluebutton_rails_to_#{version_filename}.rb"
        end
      end

      protected
      def version_filename
        migrate_to_version.gsub(".", "_")
      end

    end
  end
end
