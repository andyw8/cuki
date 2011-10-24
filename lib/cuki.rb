require 'rubygems'
require 'httpclient'
require 'yaml'
require 'CGI'
require 'json'
require 'parallel'
require File.dirname(__FILE__) + '/string_utils'
require File.dirname(__FILE__) + '/link_builder'
require File.dirname(__FILE__) + '/confluence_page'
require File.dirname(__FILE__) + '/feature_file'
require File.dirname(__FILE__) + '/test_bits'

class Cuki

  CONFIG_PATH = 'config/cuki.yaml'
  DEFAULT_CONTAINER = /h1\. Acceptance Criteria/
  PRIMARY_HEADER = "h1\."
  FEATURE_HEADER = "h2\."
  SCENARIO_HEADER = "h6\."

  FLAGS = {:skip_autoformat => '--skip-autoformat'}

  def self.invoke(args)
    new(args)
  end

  def initialize(args)
    @args = args
    validate_args
    read_config
    configure_http_client
    @link_builder = LinkBuilder.new(@config['host'])
    action = args.first
    if args.include?(FLAGS[:skip_autoformat])
      args.delete_if { |arg| FLAGS[:skip_autoformat] == arg }
      @skip_autoformat = true
    end
    configure_pull_stubs
    verify_project
    file = args[1]
    if file
      id = mappings.invert[file]
      terminate "could not get id for #{file}" unless id
      pull_feature id, file
    else
      Parallel.map(mappings, :in_processes => 4) do |id, filepath|
        pull_feature id, filepath
      end
    end
    autoformat!
  end

  private

  def verify_project
    terminate "features folder not found" unless File.exists?('features')
    puts "Verifying existing features"
    `cucumber --dry-run -P`
  end

  def read_config
    terminate "No config file found at #{CONFIG_PATH}" unless File.exist?(CONFIG_PATH)
    @config = YAML::load( File.open( CONFIG_PATH ) )
    terminate "Host not found in #{CONFIG_PATH}" unless @config["host"]
    terminate "Mappings not found in #{CONFIG_PATH}" unless @config["mappings"]
  end

  def configure_http_client
    @client = HTTPClient.new
    @client.ssl_config.set_trust_ca(ENV['CER']) if ENV['CER']
    @client.ssl_config.set_client_cert_file(ENV['PEM'], ENV['PEM']) if ENV['PEM']
  end

  def pull_feature(id, filepath)
    wiki_edit_link = @link_builder.edit(id)
    puts "Downloading #{wiki_edit_link}"
    response = @client.get wiki_edit_link
    handle_multi response.body, id
  end

  def container
    @config['container'] ||= DEFAULT_CONTAINER
  end

  def autoformat!
    unless @skip_autoformat
      `cucumber -a . --dry-run -P`
      puts "Running autoformat"
    end
  end

  def handle_multi response_body, id
    confluence_page = ConfluencePage.new(response_body)

    full_content = confluence_page.content

    terminate "Could not find acceptance criteria container" unless full_content.match(container)

    acceptance_criteria = full_content.split(container).last
    
    if acceptance_criteria.include?(PRIMARY_HEADER)
      acceptance_criteria = acceptance_criteria.split(/#{PRIMARY_HEADER}/).first
    end

    terminate "Could not match #{container} in #{id}" unless acceptance_criteria

    scenario_titles = acceptance_criteria.scan(/#{FEATURE_HEADER} (.*)/).flatten
    scenario_blocks = acceptance_criteria.split(/#{FEATURE_HEADER} .*/)
    scenario_blocks.shift

    puts "Warning: No scenarios found in doc #{id}" if scenario_titles.empty?

    combined = {}
    scenario_titles.each_with_index do |title, index|
      combined[title] = scenario_blocks[index].gsub(/h\d. ([Scenario|Scenario Outline].*)/, '\1')
    end

    combined.each do |title, content|

      feature_filename = title.parameterize
      dirpath = mappings[id]
      FileUtils.mkdir_p(dirpath)

      fname = "#{dirpath}/#{feature_filename.gsub("\r", '').parameterize}.feature"
      puts "Writing #{fname}"
      File.open(fname, 'w') do |f|
        if @config['tags']
          @config['tags'].each do |tag, token|
            f.write "@#{tag}\n" if full_content.include?(token)
          end
        end
        f.write "Feature: #{title}\n\n"
        f.write @link_builder.view(id, confluence_page.title, title)
        f.write content
      end
    end
  end

  def validate_args
    terminate "No action given" if @args.empty?
    command = @args.first
    terminate "Unknown action '#{@args.first}'" unless 'pull' == command
  end

  def mappings
    @config['mappings']
  end

  def terminate(message)
    puts message
    exit(1)
  end

end
