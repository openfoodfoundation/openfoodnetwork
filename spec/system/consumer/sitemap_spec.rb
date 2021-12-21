# frozen_string_literal: true

require 'system_helper'

describe 'sitemap' do
  let(:enterprise) { create(:distributor_enterprise) }
  let!(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }

  it "renders sitemap" do
    visit '/sitemap.xml'
    expect(page.source).to have_content return_page(enterprise_shop_url(enterprise))
    expect(page.source).to have_content return_page(group_url(group))
  end
end

private

def return_page(website)
  # routing does not include the port of the session, this method adds it
  url = URI(page.driver.browser.url)
  path = URI(website).path
  return_page = "http://#{url.host}:#{url.port}#{path}"
end
