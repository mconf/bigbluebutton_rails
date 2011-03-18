require "spec_helper"

describe BigbluebuttonRails::Generators::InstallGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../../tmp", __FILE__)
  tests BigbluebuttonRails::Generators::InstallGenerator

  before(:all) do
    prepare_destination
    run_generator
  end

  it "all files are properly created" do
    assert_migration "db/migrate/create_bigbluebutton_rails.rb"
    assert_file "config/locales/bigbluebutton_rails.en.yml"
  end

  it "all files are properly destroyed" do
    run_generator %w(), :behavior => :revoke
    assert_no_file "config/locales/bigbluebutton_rails.en.yml"
    assert_no_migration "db/migrate/create_bigbluebutton_rails.rb"
  end
end
