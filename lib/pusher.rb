class Pusher
  
  def self.push(feature_to_be_pushed, config)
  
  feature_as_in_yaml = feature_to_be_pushed.gsub('features/', '').gsub('.feature', '')
  id = config['mappings'].invert[feature_as_in_yaml]
  raise "No mapping found for #{feature_as_in_yaml}" unless id

  content = File.open(feature_to_be_pushed).read.gsub(/Feature: .*/, '')
  title = File.open(feature_to_be_pushed).read.match(/Feature: (.*)/)[1]
  response = @client.post(config['host'], {:title => title, :content => content})
  
end