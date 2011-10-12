require 'rubygems'
require 'httpclient'
require 'nokogiri'
require 'yaml'
require 'CGI'

class Cuki

  # we're assuming that the acceptance criteria starts at this point and continues to the end of the page
  START_INDICATOR = /\d\. \*Specification\*/

  def self.invoke
    new
  end

  def initialize
    read_config
    configure_http_client
    @mappings.each { |key, value|  process_mapping key, value }    
    autoformat
  end
  
  private
  
  def read_config
    config_path = 'config/cuki.yaml'

    config = YAML::load( File.open( config_path ) )

    @base = config["base"]
    raise "base not found in #{config_path}" unless @base

    @mappings = config["mappings"]
    raise "mappings not found in #{config_path}" unless @mappings
    
    @draft_indicator = config['draft']
  end
  
  def configure_http_client
    @client = HTTPClient.new
    @client.ssl_config.set_trust_ca(ENV['CER']) if ENV['CER']
    @client.ssl_config.set_client_cert_file(ENV['PEM'], ENV['PEM']) if ENV['PEM']
  end
  
  def process_mapping(key, value)
    wiki_link = @base + key.to_s

    puts "Downloading #{wiki_link}"

    response = @client.get wiki_link

    doc = Nokogiri(response.body)

    title = doc.css('title').text

    wiki_text = CGI.unescapeHTML(doc.css('#markupTextarea').text)
    wiki_text.gsub('&nbsp;', '')

    cuke_text = ''
    cuke_text += "@pending\n" if wiki_text.include?(@draft_indicator)

    title = title.split(' - ').first

    # assuming that title is format REF - TITLE - PROJECT NAME - WIKI NAME
    cuke_text += "Feature: " + title + "\n\n"

    cuke_text += "#{wiki_link}\n\n"

    raise "couldn't find start of acceptance criteria in #{title}" unless wiki_text.match(START_INDICATOR)

    cuke_text += wiki_text.split(START_INDICATOR).last

    # remove the double pipes used for table headers in Confluence
    cuke_text.gsub!('||', '|')

    # remove other noise
    cuke_text.gsub!('\\', '')

    # remove any unwanted headers
    cuke_text.gsub!(/h\d\. /, '')

    # remove an other confluence markup
    cuke_text.gsub!(/\{.*\}/, '')

    # check features folder exists
    raise "features folder not found" unless File.exists?('features')

    file_path = "features/#{value}.feature"
    dir_path = File.dirname(file_path)

    unless File.exists?(dir_path)
      Dir.mkdir(dir_path)
    end

    File.open(file_path, 'w') do |f|
      puts "Writing #{file_path}"
      f.puts cuke_text
    end
  end
  
  def autoformat
    `cucumber -a . --dry-run -P` unless ENV['SKIP_AUTOFORMAT']
  end
  
end
