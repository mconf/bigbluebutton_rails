# Example:
#   it { should have_received(:new).with(array_with_key(:name)) }
RSpec::Matchers.define :array_with_key do |expected|
  match do |actual|
    actual.has_key?(expected)
  end
end
