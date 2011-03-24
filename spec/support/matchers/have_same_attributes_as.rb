# Compares the attributes of two models or hashes, ignoring attributes generated only when saving in the db
# Example: user1.should have_same_attributes_as(User.last)
RSpec::Matchers.define :have_same_attributes_as do |expected|
  match do |actual|
    ignored = ['id', 'updated_at', 'created_at']
    actual_attr = actual.attributes unless actual.instance_of?(Hash)
    expected_attr = expected.attributes unless expected.instance_of?(Hash)
    actual_attr.except(*ignored) == expected_attr.except(*ignored)
  end
end
