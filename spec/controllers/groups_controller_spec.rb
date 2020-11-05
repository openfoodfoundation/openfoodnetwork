# frozen_string_literal: true

require 'spec_helper'

describe GroupsController, type: :controller do
  render_views

  let!(:enterprise) { create(:distributor_enterprise) }
  let!(:group) { create(:enterprise_group, enterprises: [enterprise], on_front_page: true) }

  it "loads all enterprises for group" do
    get :index
    expect(response.body).to have_text enterprise.id
  end
end
