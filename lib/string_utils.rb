class String
  def anchorize
    CGI.escape(self.gsub(' ', '').gsub("\r", ''))
  end

  def parameterize
    self.downcase.gsub(/[^a-z0-9\-]/, '_')
  end
end
