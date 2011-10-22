require 'rubygems'
require 'httpclient'
require 'yaml'
require 'CGI'
require 'json'
require 'parallel'
require File.dirname(__FILE__) + '/string_utils'
require File.dirname(__FILE__) + '/link_builder'
require File.dirname(__FILE__) + '/cleaner'
require File.dirname(__FILE__) + '/confluence_page'
require File.dirname(__FILE__) + '/feature_file'
require File.dirname(__FILE__) + '/test_bits'

class Cuki

  CONFIG_PATH = 'config/cuki.yaml'

  def self.invoke(args)
    new(args)
  end

  def initialize(args)
    validate_args args
    read_config
    configure_http_client

    action = args.first
    if args.include?('--skip-autoformat')
      args.delete_if { |arg| '--skip-autoformat' == arg }
      @skip_autoformat = true
    end
    if 'pull' == action
      configure_pull_stubs
      verify_project
      file = args[1]
      if file
        id = @config['mappings'].invert[file]
        raise "could not get id for #{file}" unless id
        pull_feature id, file
      else
        Parallel.map(@config['mappings'], :in_processes => 4) do |id, filepath|
          pull_feature id, filepath
        end
      end
      autoformat
    else
      puts "Unknown action '#{action}"
      exit(1)
    end
  end

  private
  
  def verify_project
    # check features folder exists
    raise "features folder not found" unless File.exists?('features')
    autoformat
  end
  
  def read_config
    unless File.exist?(CONFIG_PATH)
      puts "No config file found at #{CONFIG_PATH}"
      exit(1)
    end
    @config = YAML::load( File.open( CONFIG_PATH ) )
    unless @config["host"]
      puts "Host not found in #{CONFIG_PATH}"
      exit(1)
    end
    unless @config["mappings"]
      puts "Mappings not found in #{CONFIG_PATH}"
      exit(1)
    end
  end
  
  def configure_http_client
    @client = HTTPClient.new
    @client.ssl_config.set_trust_ca(ENV['CER']) if ENV['CER']
    @client.ssl_config.set_client_cert_file(ENV['PEM'], ENV['PEM']) if ENV['PEM']
  end
  
  def pull_feature(id, filepath)
    @content = ''
    
    link_builder = LinkBuilder.new(@config['host'])
    
    wiki_edit_link = link_builder.edit(id)
    wiki_view_link = link_builder.view(id)
    
    puts "Downloading #{wiki_edit_link}"
    response = @client.get wiki_edit_link
    
    confluence_page = ConfluencePage.new(response.body)

    unless confluence_page.content
      puts "Not a valid confluence page:"
      puts response.body
      exit(1)
    end
    
    unless filepath.include?('.feature')
      
      @config['container'] ||= /h1\. Acceptance Criteria/
      
      handle_multi response.body, id
    else

      feature_file = FeatureFile.new
      feature_file.title = confluence_page.title
      feature_file.link = wiki_view_link
      feature_file.content = confluence_page.content

      content = Cleaner.clean(feature_file.to_s)

      content = process_tags content

      save_file content, filepath
    end
  end
  
  def autoformat
    `cucumber -a . --dry-run -P` unless @skip_autoformat
  end
  
  def handle_multi response_body, id
    confluence_page = ConfluencePage.new(response_body)
    
    feature_title_compressed = confluence_page.title.anchorize

    @content += confluence_page.content
    
    @content = Cleaner.clean(@content)
    
    unless @content.match(@config['container'])
      puts "Could not find acceptance criteria container"
      exit(1)
    end
    acceptance_criteria_block = @content.split(@config['container']).last
    if acceptance_criteria_block.match(/h1\./)
      acceptance_criteria_block = acceptance_criteria_block.split(/h1\./).first
    end
    unless acceptance_criteria_block
      puts "Could not match #{@config['container']} in #{id}" 
      exit(1)
    end
    acceptance_criteria = acceptance_criteria_block
    scenario_titles = acceptance_criteria.scan(/h2\. (.*)/).flatten
    scenario_blocks = acceptance_criteria.split(/h2\. .*/)
    scenario_blocks.shift

    combined = {}
    found = 0
    scenario_titles.each_with_index do |title, index|
      combined[title] = scenario_blocks[index].gsub(/h6. (.*)/, '\1')
      found += 1
    end
    if 0 == found
      puts "No scenarios found in doc #{id}"
      exit(1)
    end
    combined.each do |title, content|
      
      tags = []
      if @config['tags']
        @config['tags'].each_pair do |tag, snippet|
          tags << "@#{tag}"  if @content.include?(snippet)
        end
      end
      unless tags.empty?
        content = tags.join(' ') + "\n" + content
        # tags.each do |tag|
        #   content.gsub!(@config['tags'][tag.gsub('@', '')], '')
        # end
      end
      
      scenario_title_compressed = title.anchorize
      feature_filename = title.parameterize

      dirpath = @config['mappings'][id]

      FileUtils.mkdir_p(dirpath)
      
      fname = "#{dirpath}/#{feature_filename.gsub("\r", '').parameterize}.feature"
      File.open(fname, 'w') do |f|
        puts "Writing #{fname}"
        f.write "Feature: #{title}\n\n"
        link = @config['host'] + "/pages/viewpage.action?pageId=#{id}##{feature_title_compressed}-#{scenario_title_compressed}"
        f.write link
        f.write content
      end
    end
  end
  
  def process_tags(content)
    tags = []
    if @config['tags']
      @config['tags'].each_pair do |tag, snippet|
        tags << "@#{tag}"  if content.include?(snippet)
      end
    end
    unless tags.empty?
      content = tags.join(' ') + "\n" + content
      tags.each do |tag|
        content.gsub!(@config['tags'][tag.gsub('@', '')], '')
      end
    end
    content
  end
  
  def save_file(content, filepath)
    dir_path = File.dirname(filepath)

    FileUtils.mkdir_p(dir_path) unless File.exists?(dir_path)

    File.open(filepath, 'w') do |f|
      puts "Writing #{filepath}"
      f.puts content
    end
  end

  def validate_args args
    if args.empty?
      puts "No action given"
      exit(1)
    end
  end
  
end
