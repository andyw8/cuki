# terrible hack
if File.exist?('stubs.json') || File.exist?('stubs.json')
  require 'webmock'
  include WebMock::API
end

def configure_pull_stubs
  if File.exist?('stubs.json')
    stubs = JSON.parse(File.open('stubs.json').read)
    stubs.each_pair do |url, body|
      stub_request(:get, url).to_return(:status => 200, :body => body, :headers => {})
    end
    FileUtils.rm 'stubs.json'
  end
end