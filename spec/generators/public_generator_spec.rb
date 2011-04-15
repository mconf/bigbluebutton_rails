require "spec_helper"

describe BigbluebuttonRails::Generators::PublicGenerator do
  include GeneratorSpec::TestCase
  destination File.expand_path("../../../tmp", __FILE__)
  tests BigbluebuttonRails::Generators::PublicGenerator

  before(:all) do
    prepare_destination
  end

  it "creates and revokes all files properly" do
    run_generator
    assert_files
    run_generator %w(), :behavior => :revoke
    assert_files(false)
  end

  def assert_files(assert_exists=true)
    files = [
      "public/images/loading.gif",
      "public/javascripts/jquery.min.js"
    ]
    if assert_exists
      files.each { |f| assert_file f }
    else
      files.each { |f| assert_no_file f }
    end
  end

end
