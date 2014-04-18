require 'spec_helper'

feature 'Home', js: true do
  let(:distributor) { create(:distributor_enterprise) }
  it "shows all hubs" do
    distributor
    visit "/" 
    page.should have_content distributor.name
    find("hub a.row").click
    page.should have_content "Shop at #{distributor.name}" 
  end
end
