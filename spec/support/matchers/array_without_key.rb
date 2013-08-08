# Example:
#   it { should have_received(:new).with(array_without_key(:name)) }
RSpec::Matchers.define :array_without_key do |expected|
  match do |actual|
    not actual.has_key?(expected)
  end
end
