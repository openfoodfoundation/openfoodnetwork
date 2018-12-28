require 'spec_helper'

describe 'sitemap/index', type: :view do
  let(:enterprise) { create(:distributor_enterprise) }
  let(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }

  it 'renders the sitemap' do
    assign(:page_urls, [])
    assign(:enterprises, [enterprise])
    assign(:groups, [group])

    render

    expect(rendered).to have_content enterprise_shop_url(enterprise)
    expect(rendered).to have_content group_url(group)
  end
end
