require 'spec_helper'

describe 'shared/menu/_large_menu.html.haml', type: :view do
  let(:current_user) { double(:current_user) }

  before do
    stub_template 'shared/_signed_in' => ''
    stub_template 'shared/menu/_cart' => ''
  end

  it 'displays the /shops link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }
    expect(rendered).to have_link(t(:menu_1_title), href: shops_path)
  end

  it 'displays the /map link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }
    expect(rendered).to have_link(t(:menu_2_title), href: map_path)
  end

  context 'when the third menu item is not configured' do
    it 'renders /producers as href' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }
      expect(rendered).to have_link(t(:menu_3_title), href: producers_path)
    end
  end

  context 'when the third menu item is configured' do
    around do |example|
      ENV['MENU_3_URL'] = '/foo'
      example.run
      ENV.delete('MENU_3_URL')
    end

    it 'renders the configured value as href' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }
      expect(rendered).to have_link(t(:menu_3_title), href: '/foo')
    end
  end

  context 'when the fourth menu item is not configured' do
    it 'renders /groups as href' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }
      expect(rendered).to have_link(t(:menu_4_title), href: groups_path)
    end
  end

  context 'when the fourth menu item is configured' do
    around do |example|
      ENV['MENU_4_URL'] = '/foo'
      example.run
      ENV.delete('MENU_4_URL')
    end

    it 'renders the configured value as href' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }
      expect(rendered).to have_link(t(:menu_4_title), href: '/foo')
    end
  end
end
