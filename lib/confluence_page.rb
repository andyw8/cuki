require 'nokogiri'

class ConfluencePage
  
  def initialize(response)
    @doc = Nokogiri(response)
  end
  
  def title
    @doc.at('#content-title')[:value]
  end
  
  def content
    content = CGI.unescapeHTML @doc.css('#markupTextarea').text
    
    content.gsub!('&nbsp;', '')
    
    # remove the double pipes used for table headers in Confluence
    content.gsub!('||', '|')

    # remove other noise
    content.gsub!("\r\n", "\n")
    content.gsub!("\\\\\n", '')
    content.gsub!('\\', '')

    # remove any unwanted headers
    content.gsub!(/h\d\. (Scenario: .*)/, '\1')
    content.gsub!(/h\d\. (Scenario Outline: .*)/, '\1')
    content.gsub!(/h\d\. (Background: .*)/, '\1')
    
    #Remove fancy quotes
    content.gsub!('’', "'")
    content.gsub!('‘', "'")
    content.gsub!('“', '"')
    content.gsub!('”', '"')
    
    content.gsub!(/^#(.*)/, '-' + '\1')    
    content
  end

end