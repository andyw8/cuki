class String
  def anchorize
    self.gsub(' ', '')
  end

  def parameterize
    self.downcase.gsub(' ', '_')
  end
end
