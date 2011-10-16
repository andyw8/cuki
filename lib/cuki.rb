require 'rubygems'
require 'httpclient'
require 'nokogiri'
require 'yaml'
require 'CGI'
require 'webmock'
require 'json'
include WebMock::API

class Cuki

  CONFIG_PATH = 'config/cuki.yaml'

  def self.invoke(args)
    new(args)
  end

  def initialize(args)
    if args.empty?
      puts "No action given"
      exit(1)
    end
    parse_config_file
    action = args.first
    configure_http_client
    if 'pull' == action
      configure_pull_stubs
      verify_project
      file = args[1]
      if file
        key = file.gsub('features/', '').gsub('.feature', '')
        id = @config['mappings'].invert[key]
        process_feature id, key
      else
        @config['mappings'].each { |id, filepath|  process_feature id, filepath }
      end
      #autoformat
    elsif 'push' == action
      configure_push_stubs
      Pusher.push file, @config
    else
      puts "Unknown action '#{action}"
      exit(1)
    end
  end

  private
  
  def verify_project
    # check features folder exists
    raise "features folder not found" unless File.exists?('features')
    #autoformat
  end
  
  def parse_config_file
    unless File.exist?(CONFIG_PATH)
      puts "No config file found at #{CONFIG_PATH}"
      exit(1)
    end
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
        
    unless doc.at('#content-title')
      puts "Not a valid confluence page:"
      puts doc.to_s
      exit(1)
    end

    @content += "Feature: " + doc.at('#content-title')[:value] + "\n\n"
    @content += "#{wiki_link}\n\n"
    @content += CGI.unescapeHTML(doc.css('#markupTextarea').text)

    clean

    process_tags

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
      @config['tags'].each_pair do |tag, snippet|
        tags << "@#{tag}"  if @content.include?(snippet)
      end
    end
    unless tags.empty?
      @content = tags.join(' ') + "\n" + @content
      tags.each do |tag|
        @content.gsub!(@config['tags'][tag.gsub('@', '')], '')
      end
    end
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
  
  def configure_pull_stubs
    if File.exist?('stubs.json')
      stubs = JSON.parse(File.open('stubs.json').read)
      stubs.each_pair do |url, body|
        stub_request(:get, url).to_return(:status => 200, :body => body, :headers => {})
      end
      FileUtils.rm 'stubs.json'
    end
  end
  
  def configure_push_stubs
    if File.exist?('push_stubs.json')
      stubs = JSON.parse(File.open('push_stubs.json').read)
      stubs.each do |a|
        stub_request(:post, "http://mywiki/").
                with(:body => {"title" => a['title'], "content"=> "\n\n" + a['content']},
                     :headers => {'Content-Type'=>'application/x-www-form-urlencoded'}).
                to_return(:status => 200, :body => "", :headers => {})
      end
      FileUtils.rm 'push_stubs.json'
    end
  end
  
end
