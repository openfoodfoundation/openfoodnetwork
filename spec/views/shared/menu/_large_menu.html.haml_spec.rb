require 'spec_helper'

describe 'shared/menu/_large_menu.html.haml', type: :view do
  let(:current_user) { double(:current_user) }

  before do
    stub_template 'shared/_signed_in' => ''
    stub_template 'shared/menu/_cart' => ''
  end

  context 'when the /shops link has no translation' do
    it 'renders /shops as href' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }

      expect(rendered).to have_link(t(:menu_1_title), href: shops_path)
    end
  end

  context 'when the /shops link has a translation' do
    before do
      allow(I18n).to receive(:t).with('menu_2_url', default: map_path) { map_path }
      allow(I18n).to receive(:t).with('menu_3_url', default: producers_path) { producers_path }
      allow(I18n).to receive(:t).with('menu_4_url', default: groups_path) { groups_path }

      allow(I18n).to receive(:t).with('menu_1_url', default: shops_path).and_return('/foo')
    end

    it 'renders the translation as href' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }

      expect(rendered).to have_link(t(:menu_1_title), href: '/foo')
    end
  end

  context 'when the /map link has no translation' do
    it 'displays the /map link' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }

      expect(rendered).to have_link(t(:menu_2_title), href: map_path)
    end
  end

  context 'when the /map link has a translation' do
    before do
      allow(I18n).to receive(:t).with('menu_1_url', default: shops_path) { shops_path }
      allow(I18n).to receive(:t).with('menu_3_url', default: producers_path) { producers_path }
      allow(I18n).to receive(:t).with('menu_4_url', default: groups_path) { groups_path }

      allow(I18n).to receive(:t).with('menu_2_url', default: map_path).and_return('/foo')
    end

    it 'renders the translation as href' do
      render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }

      expect(rendered).to have_link(t(:menu_2_title), href: '/foo')
    end
  end

  it 'displays the /producers link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }

    expect(rendered).to have_link(t(:menu_3_title), href: producers_path)
  end

  it 'displays the /groups link' do
    render partial: 'shared/menu/large_menu', locals: { spree_current_user: current_user }

    expect(rendered).to have_link(t(:menu_4_title), href: groups_path)
  end
end
