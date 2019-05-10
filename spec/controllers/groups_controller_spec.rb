require 'spec_helper'

describe GroupsController, type: :controller do
  render_views
  let(:enterprise) { create(:distributor_enterprise) }
  let!(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }
  it "gets all visible groups" do
    allow(EnterpriseGroup).to receive_message_chain :on_front_page, :by_position
    expect(EnterpriseGroup).to receive :on_front_page
    get :index
  end

  it "loads all enterprises for group" do
    get :index
    expect(response.body).to have_text enterprise.id
  end
end
