require 'nokogiri'

class ConfluencePage
  
  def initialize(response)
    @doc = Nokogiri(response)
  end
  
  def title
    @doc.at('#content-title')[:value]
  end
  
  def content
    CGI.unescapeHTML @doc.css('#markupTextarea').text
  end

end