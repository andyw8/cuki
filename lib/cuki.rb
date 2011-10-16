require 'rubygems'
require 'httpclient'
require 'nokogiri'
require 'yaml'
require 'CGI'

class Cuki

  CONFIG_PATH = 'config/cuki.yaml'

  def self.invoke(args)
    new(args)
  end

  def initialize(args)
    raise "No command given" if args.empty?
    parse_config_file
    command = args.first
    if 'pull' == command
      verify_project
      configure_http_client
      @config['mappings'].each { |id, filepath|  process_feature id, filepath }    
      autoformat
    elsif 'push' == command
      feature_to_be_pushed = args[1] # e.g. features/products/add_product.feature
      feature_as_in_yaml = feature_to_be_pushed.gsub('features/', '').gsub('.feature', '')
      id = @config['mappings'].invert[feature_as_in_yaml]
      raise "No mapping found for #{feature_as_in_yaml}" unless id
    else
      raise "Unknown command '#{command}"
    end
  end

  private
  
  def verify_project
    # check features folder exists
    raise "features folder not found" unless File.exists?('features')
    autoformat
  end
  
  def parse_config_file
    @config = YAML::load( File.open( CONFIG_PATH ) )
    raise "Host not found in #{CONFIG_PATH}" unless @config["host"]
    raise "Mappings not found in #{CONFIG_PATH}" unless @config["mappings"]
  end
  
  def configure_http_client
    @client = HTTPClient.new
    @client.ssl_config.set_trust_ca(ENV['CER']) if ENV['CER']
    @client.ssl_config.set_client_cert_file(ENV['PEM'], ENV['PEM']) if ENV['PEM']
  end
  
  def process_feature(id, filepath)
    @content = ''
    wiki_link = @config['host'] + '/pages/editpage.action?pageId=' + id.to_s
    puts "Downloading #{wiki_link}"
    response = @client.get wiki_link
    doc = Nokogiri(response.body)
        
    process_tags

    @content += "Feature: " + doc.at('#content-title')[:value] + "\n\n"
    @content += "#{wiki_link}\n\n"
    @content += CGI.unescapeHTML(doc.css('#markupTextarea').text)

    clean
    save_file filepath
  end
  
  def autoformat
    `cucumber -a . --dry-run -P` unless ENV['SKIP_AUTOFORMAT']
  end
  
  def clean
    
    @content.gsub('&nbsp;', '')
    
    # remove the double pipes used for table headers in Confluence
    @content.gsub!('||', '|')

    # remove other noise
    @content.gsub!("\r\n", "\n")
    @content.gsub!("\\\\\n", '')
    @content.gsub!('\\', '')

    # remove any unwanted headers
    @content.gsub!(/h\d\. (Scenario: .*)/, '\1')
    @content.gsub!(/h\d\. (Scenario Outline: .*)/, '\1')

  end
  
  def process_tags
    tags = []
    if @config['tags']
      @config['tags'].each do |tag, snippet|
        tags << "@#{tag}" if @content.include?(snippet)
      end
    end
    @content += tags.join(' ') + "\n" unless tags.empty?
  end
  
  def save_file(filepath)
    full_filepath = "features/#{filepath}.feature"
    dir_path = File.dirname(full_filepath)

    Dir.mkdir(dir_path) unless File.exists?(dir_path)      

    File.open(full_filepath, 'w') do |f|
      puts "Writing #{full_filepath}"
      f.puts @content
    end
  end
  
end
