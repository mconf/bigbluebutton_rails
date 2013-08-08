# Example:
#   before(:each) { get :index, :format => 'json' }
#   it { should respond_with_content_type("application/json") }
RSpec::Matchers.define :respond_with_content_type do |expected|
  match do |controller|
    response.header['Content-Type'].include?(expected)
  end
end
