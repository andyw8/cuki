Given /^a Confluence page on "([^"]*)" with id (\d+):$/ do |host, id, content|

  # Since the command-line app runs in a difference process, we need serialize
  # the URLs to be stubbed

  @stubs ||= {}
  @stubs["http://#{host}/pages/viewpage.action?pageId=#{id}"] = content
  
  File.open('stubs.json', 'w') do |f|
    f.write @stubs.to_json
  end

end

Given /^no file named "([^"]*)" exists$/ do |file|
  File.delete(file) if File.exist?(file)
end
