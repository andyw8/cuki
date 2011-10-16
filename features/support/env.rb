#ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"

require 'aruba/cucumber'
require 'webmock/cucumber'

Before do
  @dirs = ["."]
end