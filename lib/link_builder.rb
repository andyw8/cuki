class LinkBuilder
  
  def initialize(host)
    @host = host
  end
  
  def edit(id)
    @host + '/pages/editpage.action?pageId=' + id.to_s
  end
  
  def view(id)
    @host + '/pages/viewpage.action?pageId=' + id.to_s
  end
  
end
