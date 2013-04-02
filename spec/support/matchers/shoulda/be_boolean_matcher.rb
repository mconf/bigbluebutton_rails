module Shoulda
  module Matchers
    module ActiveModel # :nodoc

      # Usage example: be_boolean(:private)
      def be_boolean(attribute)
        BeBooleanMatcher.new(attribute)
      end

      class BeBooleanMatcher < ValidationMatcher # :nodoc:
        def initialize(attribute)
          @attribute = attribute
        end

        def matches?(subject)
          @subject = subject
          disallows_value_of(nil) &&
            disallows_value_of("") &&
            allows_value_of(true) &&
            allows_value_of(false)
        end

        def description
          description = "#{@attribute} should be a boolean"
        end

        def failure_message
          "Expected #{@attribute} to be a boolean"
        end

        def negative_failure_message
          "Did not expect #{@attribute} to be a boolean"
        end

      end
    end
  end
end
