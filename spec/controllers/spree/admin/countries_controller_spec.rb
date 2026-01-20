# frozen_string_literal: true

module Spree
  module Admin
    RSpec.describe CountriesController do
      include AuthenticationHelper

      describe "#update" do
        before { controller_login_as_admin }

        it "updates the name of an existing country" do
          country = create(:country)
          spree_put :update, id: country.id,
                             country: { name: "Kyrgyzstan" }

          expect(response).to redirect_to spree.admin_countries_url
          expect(country.reload.name).to eq "Kyrgyzstan"
        end
      end
    end
  end
end
