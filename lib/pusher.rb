class Pusher
  
  def self.push(feature_to_be_pushed, config)
  
  id = config['mappings'].invert[feature_to_be_pushed]
  raise "No mapping found for #{feature_to_be_pushed}" unless id

  content = File.open(feature_to_be_pushed).read.gsub(/Feature: .*/, '')
  title = File.open(feature_to_be_pushed).read.match(/Feature: (.*)/)[1]
  response = @client.post(config['host'], {:title => title, :content => content})
  
end