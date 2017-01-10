class SitemapController < ApplicationController
  layout nil

  def index
    headers['Content-Type'] = 'application/xml'
    @pages = ['shops', 'map', 'producers', 'groups']
    @enterprises = Enterprise.is_hub
    @groups = EnterpriseGroup.all
    respond_to :xml
  end
end
