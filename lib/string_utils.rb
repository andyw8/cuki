class String
  def anchorize
    CGI.escape(self.gsub(' ', '').gsub("\r", ''))
  end

  def parameterize
    self.downcase.gsub(' ', '_')
  end
end
