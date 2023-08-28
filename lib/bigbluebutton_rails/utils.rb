require 'browser'

module BigbluebuttonRails

  # Returns whether the current client should use the mobile client
  # or the desktop client.
  def self.use_mobile_client?(browser)
    browser.mobile? || browser.tablet?
  end

  # Just a wrapper around the Rails method to convert values to boolean
  def self.value_to_boolean(value)
    ActiveRecord::Type::Boolean.new.cast(value)
  end
end
