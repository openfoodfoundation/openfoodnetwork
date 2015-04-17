require 'spec_helper'

feature 'Groups', js: true do
  include AuthenticationWorkflow
  include UIComponentHelper

  let(:enterprise) { create(:distributor_enterprise) }
  let!(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }

  it "renders groups" do
    visit groups_path
    page.should have_content group.name
  end

  it "renders enterprise modals for groups" do
    visit groups_path
    page.should have_content group.name
  end
end
