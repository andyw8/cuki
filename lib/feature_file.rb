class FeatureFile
  
  attr_accessor :title, :link, :content
  
  def initialize
    @title = nil
    @link = nil
    @content = nil
  end
  
  def to_s
    result = "Feature: " + title + "\n\n"
    result += "#{link}\n\n"
    result += content
    result
  end
  
end
