require 'rails/generators/active_record'

module BigbluebuttonRails
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      argument :migrate_to_version, :type => :string, :default => "", :description => "Generate migration to this version"
      class_option :migration_only, :type => :boolean, :default => false, :description => "Generate only the migration file"
      source_root File.expand_path("../../../../", __FILE__) # set to gem root

      desc "Creates the migrations and locale files. Also used to create migrations when updating the gem version."

      def copy_locale
        copy_file "config/locales/en.yml", "config/locales/bigbluebutton_rails.en.yml" unless options.migration_only?
      end

      def self.next_migration_number(dirname)
        ActiveRecord::Generators::Base.next_migration_number(dirname)
      end

      def create_migration_file
        if migrate_to_version.blank?
          migration_template "#{migration_path}/migration.rb", "db/migrate/create_bigbluebutton_rails.rb"
        else
          migration_template "#{migration_path}/migration_#{version_filename}.rb", "db/migrate/bigbluebutton_rails_to_#{version_filename}.rb"
        end
      end

      def create_schedule
        unless options.migration_only?
          create_file 'config/schedule.rb'
          content = File.read(File.expand_path("../../../../config/schedule.rb", __FILE__))
          append_file 'config/schedule.rb', "\n#{content}" unless behavior == :revoke
        end
      end

      protected

      def migration_path
        File.join("lib", "generators", "bigbluebutton_rails", "templates")
      end

      def version_filename
        migrate_to_version.gsub(".", "_")
      end

    end
  end
end
