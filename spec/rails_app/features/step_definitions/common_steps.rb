When /(?:|I ) go(es)? to (.+) page$/i do |_, page_name|
  visit path_to(page_name)
end
