require 'spec_helper'

feature 'sitemap' do
  let(:enterprise) { create(:distributor_enterprise) }
  let!(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }

  it "renders sitemap" do
    visit '/sitemap.xml'
    expect(page).to have_content enterprise_shop_url(enterprise)
    expect(page).to have_content group_url(group)
  end
end
