# frozen_string_literal: true

class SitemapController < ApplicationController
  layout nil

  def index
    headers['Content-Type'] = 'application/xml'
    @page_urls = [shops_url, map_url, producers_url, groups_url]
    @enterprises = Enterprise.is_hub
    @groups = EnterpriseGroup.all
    respond_to :xml
  end
end
