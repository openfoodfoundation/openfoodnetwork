require 'spec_helper'

describe GroupsController do
  it "gets all visible groups" do
    EnterpriseGroup.stub_chain :on_front_page, :by_position
    EnterpriseGroup.should_receive :on_front_page
    get :index
  end
end
