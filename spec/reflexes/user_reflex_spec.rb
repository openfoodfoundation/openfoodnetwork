# frozen_string_literal: true

require "reflex_helper"

describe UserReflex, type: :reflex do
  let(:current_user) { create(:user) }
  let(:context) { { url: spree.admin_dashboard_url, connection: { current_user: } } }

  describe "#accept_terms_of_services" do
    subject(:reflex) { build_reflex(method_name: :accept_terms_of_services, **context) }

    it "updates terms_of_service_accepted_at" do
      expect {
        reflex.run(:accept_terms_of_services)
        current_user.reload
      }.to change{ current_user.terms_of_service_accepted_at }
    end

    it "removes banner from the page" do
      expect(reflex.run(:accept_terms_of_services)).to morph("#banner-container").with("")
    end
  end
end
