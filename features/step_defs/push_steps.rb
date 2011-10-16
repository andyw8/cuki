Then /^the feature should be pushed to "([^"]*)" with title "([^"]*)" with:$/ do |url, title, content|
  
  @push_stubs ||= []
  @push_stubs << {
    'url' => url,
    'title' => title,
    'content' => content
  }
  
  File.open('push_stubs.json', 'w') { |f| f.write @push_stubs.to_json }
end
