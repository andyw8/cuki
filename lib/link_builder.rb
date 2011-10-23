class LinkBuilder
  
  def initialize(host)
    @host = host
  end
  
  def edit(id)
    @host + '/pages/editpage.action?pageId=' + id.to_s
  end
  
  def view(id, feature=nil, scenario=nil)
    link = @host + '/pages/viewpage.action?pageId=' + id.to_s
    link += '#' + feature.anchorize  if feature
    link += '-' + scenario.anchorize if scenario
  end
  
end
