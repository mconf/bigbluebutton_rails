require "spec_helper"

describe BigbluebuttonRails::Generators::InstallGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../../tmp", __FILE__)
  tests BigbluebuttonRails::Generators::InstallGenerator

  context "standard install" do
    before(:all) do
      prepare_destination
      run_generator
    end

    it "all files are properly created" do
      assert_migration "db/migrate/create_bigbluebutton_rails.rb"
      assert_file "config/locales/bigbluebutton_rails.en.yml"
      assert_file "public/stylesheets/bigbluebutton_rails.css"
    end

    it "all files are properly destroyed" do
      run_generator %w(), :behavior => :revoke
      assert_no_file "config/locales/bigbluebutton_rails.en.yml"
      assert_no_migration "db/migrate/create_bigbluebutton_rails.rb"
      assert_no_file "public/stylesheets/bigbluebutton_rails.css"
    end
  end

  context "without locale" do
    before(:all) do
      prepare_destination
      run_generator %w{ --skip-locale }
    end

    it "the locale is not created" do
      assert_no_file "config/locales/bigbluebutton_rails.en.yml"
    end
  end

  context "without stylesheet" do
    before(:all) do
      prepare_destination
      run_generator %w{ --skip-stylesheet }
    end

    it "the stylesheet is not created" do
      assert_no_file "public/stylesheets/bigbluebutton_rails.css"
    end
  end

  context "migrating to version" do
    before { prepare_destination }

    ["0.0.5"].each do |version|
      context "#{version}" do
        before { run_generator [ version ] }

        it "all files are properly created" do
          assert_migration "db/migrate/bigbluebutton_rails_to_#{version.gsub(".", "_")}.rb"
        end

        it "all files are properly destroyed" do
          run_generator [ version ], :behavior => :revoke
          assert_no_migration "db/migrate/bigbluebutton_rails_to_#{version.gsub(".", "_")}.rb"
        end
      end
    end
  end

end
