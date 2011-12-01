module ContentHelpers

  def page_has_content(text)
    if page.respond_to? :should
      page.should have_content(text)
    else
      assert page.has_content?(text)
    end
  end

  def page_doesnt_have_content(text)
    if page.respond_to? :should
      page.should_not have_content(text)
    else
      assert !page.has_content?(text)
    end
  end

  def has_content(text)
    if respond_to? :should
      should have_content(text)
    else
      assert has_content?(text)
    end
  end

  def doesnt_have_content(text)
    if respond_to? :should
      should_not have_content(text)
    else
      assert !has_content?(text)
    end
  end

end

World(ContentHelpers)
