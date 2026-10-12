# frozen_string_literal: true

RSpec.describe Spree::Admin::StatesController do
  include AuthenticationHelper

  let(:country) { create(:country) }

  before { controller_login_as_admin }

  describe "#new_object_url" do
    it "links to a new state of the country" do
      spree_get :index, country_id: country.id

      expect(controller.__send__(:new_object_url)).to eq new_admin_country_state_url(country)
    end
  end
end
