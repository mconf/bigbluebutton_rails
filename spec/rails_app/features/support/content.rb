module ContentHelpers

  # Passing the xpath in the methods below is useful to check for
  # content in any item of a list, for example
  # page_has_content("Hi", './/li[@id="my-element"]'

  def page_has_content(text, xpath=nil)
    if xpath.nil?
      page.should have_content(text)
    else
      page.should_not have_xpath(xpath, :text => text)
    end
  end

  def page_doesnt_have_content(text, xpath=nil)
    if xpath.nil?
      page.should_not have_content(text)
    else
      page.should_not have_xpath(xpath, :text => text)
    end
  end

  def has_content(text, xpath=nil)
    if xpath.nil?
      should have_content(text)
    else
      should have_xpath(xpath, :text => text)
    end
  end

  def doesnt_have_content(text, xpath=nil)
    if xpath.nil?
      should_not have_content(text)
    else
      should_not have_xpath(xpath, :text => text)
    end
  end

end

World(ContentHelpers)
