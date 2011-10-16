#ENV['PATH'] = "#{File.expand_path(File.dirname(__FILE__) + '/../../bin')}#{File::PATH_SEPARATOR}#{ENV['PATH']}"

require 'aruba/cucumber'
require 'webmock/cucumber'

Before do
  @dirs = ["."]
  cleanup
end

After do
  cleanup
end

def cleanup
  FileUtils.rm_rf 'features/products'
end