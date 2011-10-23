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
  PRIMARY_HEADER = "h1\."
  FEATURE_HEADER = "h2\."
  SCENARIO_HEADER = "h6\."

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
        id = mappings.invert[file]
        raise "could not get id for #{file}" unless id
        pull_feature id, file
      else
        Parallel.map(mappings, :in_processes => 4) do |id, filepath|
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

    handle_multi response.body, id

  end
  
  def container
    @config['container'] ||= /h1\. Acceptance Criteria/
  end
  
  def autoformat
    `cucumber -a . --dry-run -P` unless @skip_autoformat
  end
  
  def handle_multi response_body, id
    confluence_page = ConfluencePage.new(response_body)
    
    feature_title_compressed = confluence_page.title.anchorize

    @content += confluence_page.content
    
    @content = Cleaner.clean(@content)
    
    unless @content.match(container)
      puts "Could not find acceptance criteria container"
      exit(1)
    end
    acceptance_criteria_block = @content.split(container).last
    if acceptance_criteria_block.include?(PRIMARY_HEADER)
      acceptance_criteria_block = acceptance_criteria_block.split(/#{PRIMARY_HEADER}/).first
    end
    unless acceptance_criteria_block
      puts "Could not match #{container} in #{id}" 
      exit(1)
    end
    
    acceptance_criteria = acceptance_criteria_block
    
    scenario_titles = acceptance_criteria.scan(/#{FEATURE_HEADER} (.*)/).flatten
    scenario_blocks = acceptance_criteria.split(/#{FEATURE_HEADER} .*/)
    scenario_blocks.shift

    combined = {}
    found = 0
    scenario_titles.each_with_index do |title, index|
      combined[title] = scenario_blocks[index].gsub(/#{SCENARIO_HEADER} (.*)/, '\1')
      found += 1
    end
    if 0 == found
      puts "No scenarios found in doc #{id}"
      exit(1)
    end
    combined.each do |title, content|
      
      scenario_title_compressed = title.anchorize
      feature_filename = title.parameterize

      dirpath = mappings[id]

      FileUtils.mkdir_p(dirpath)
      
      fname = "#{dirpath}/#{feature_filename.gsub("\r", '').parameterize}.feature"
      puts "Writing #{fname}"
      File.open(fname, 'w') do |f|
        if @config['tags']
          @config['tags'].each do |tag, token|
            f.write "@#{tag}\n" if acceptance_criteria.include?(token)
          end
        end
        f.write "Feature: #{title}\n\n"
        link = @config['host'] + "/pages/viewpage.action?pageId=#{id}##{feature_title_compressed}-#{scenario_title_compressed}"
        f.write link
        f.write content
      end
    end
  end

  def validate_args args
    if args.empty?
      puts "No action given"
      exit(1)
    end
  end
  
  def mappings
    @config['mappings']
  end
  
end
