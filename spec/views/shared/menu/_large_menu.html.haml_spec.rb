require 'spec_helper'

describe 'shared/menu/_large_menu.html.haml', type: :view do
  before do
    stub_template 'shared/_signed_in' => ''
    stub_template 'shared/menu/_cart' => ''
  end

  it 'displays the /shops link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: double(:current_user) }

    expect(rendered).to have_link(t(:menu_1_title), href: shops_path)
  end

  it 'displays the /map link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: double(:current_user) }

    expect(rendered).to have_link(t(:menu_2_title), href: map_path)
  end

  it 'displays the /producers link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: double(:current_user) }

    expect(rendered).to have_link(t(:menu_3_title), href: producers_path)
  end

  it 'displays the /producers link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: double(:current_user) }

    expect(rendered).to have_link(t(:menu_4_title), href: groups_path)
  end
end
