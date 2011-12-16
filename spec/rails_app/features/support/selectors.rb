module HtmlSelectorsHelpers

  # Creates a selector (a string) using xpath or css selectors (default)
  def make_selector(element, attrs={}, method=:css)
    case method
    when :xpath
      # TODO: test xpath with multiple attrs
      "//#{element}" + attrs.map{ |k,v| "[@#{k.to_s}='#{v.to_s}']" }.join
    else # :css
      "#{element}" + attrs.map{ |k,v| "[#{k.to_s}='#{v.to_s}']" }.join
    end
  end

  # Ensures the page has certain element with certain attributes
  # Same as has_element but for the entire page
  def page_has_element(element, attrs={}, method=:css)
    selector = make_selector(element, attrs, method)
    if page.respond_to? :should
      case method
      when :xpath
        page.should have_xpath(selector)
      else # :css
        page.should have_selector(selector)
      end
    else
      case method
      when :xpath
        assert page.has_xpath?(selector)
      else # :css
        assert page.has_selector?(selector)
      end
    end
  end

  # Ensures there is a certain element with certain attributes
  # Used inside "within" blocks
  # Exemples (both will have the same result):
  #   has_element("input", { :name => 'meeting', :type => 'hidden', :value => 'my-value' })
  #   has_element("input[name='meeting'][type='hidden'][value='my-value']")
  def has_element(element, attrs={}, method=:css)
    selector = make_selector(element, attrs, method)
    if respond_to? :should
      case method
      when :xpath
        should have_xpath(selector)
      else # :css
        should have_selector(selector)
      end
    else
      case method
      when :xpath
        assert has_xpath?(selector)
      else # :css
        assert has_xpath?(selector)
      end
    end
  end

  def doesnt_have_element(element, attrs={}, method=:css)
    selector = make_selector(element, attrs, method)
    if respond_to? :should
      case method
      when :xpath
        should_not have_xpath(selector)
      else # :css
        should_not have_selector(selector)
      end
    else
      case method
      when :xpath
        assert !has_xpath?(selector)
      else # :css
        assert !has_xpath?(selector)
      end
    end
  end

  # Creates a css selector to match a form with certain action, method and possibly other attribues
  def form_selector(action, method='post', attrs={})
    attrs[:action] = action
    attrs[:method] = method
    make_selector("form", attrs)
  end

  # Maps a name to a selector. Used primarily by the
  #
  #   When /^(.+) within (.+)$/ do |step, scope|
  #
  # step definitions in web_steps.rb
  #
  def selector_for(locator)
    case locator

    when "the page"
      "html > body"

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    #  when /^the (notice|error|info) flash$/
    #    ".flash.#{$1}"

    # You can also return an array to use a different selector
    # type, like:
    #
    #  when /the header/
    #    [:xpath, "//header"]

    # This allows you to provide a quoted selector as the scope
    # for "within" steps as was previously the default for the
    # web steps:
    when /^"(.+)"$/
      $1

    else
      raise "Can't find mapping from \"#{locator}\" to a selector.\n" +
        "Now, go and add a mapping in #{__FILE__}"
    end
  end
end

World(HtmlSelectorsHelpers)
