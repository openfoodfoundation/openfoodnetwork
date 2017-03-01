require 'spec_helper'

describe 'spree/layouts/admin/_login_nav.html.haml' do

  it 'display the application version in admin navbar' do
    def  view.spree_current_user
      FactoryGirl.build(:user)
    end

    render

    expect(rendered).to have_css('span#app_version')
  end
end