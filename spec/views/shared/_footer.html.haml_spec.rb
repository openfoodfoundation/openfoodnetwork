require 'spec_helper'

describe 'shared/_footer.html.haml' do
  it 'display the application version' do
    render
    expect(rendered).to have_css('p#app_version')
  end
end