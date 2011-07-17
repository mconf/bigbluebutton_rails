module FormsHelpers

  # Creates a css selector to match a form with certain action, method and possibly other attribues
  def form_selector(action, method='post', attrs={})
    attrs[:action] = action
    attrs[:method] = method
    make_selector("form", attrs)
  end

end

World(FormsHelpers)
