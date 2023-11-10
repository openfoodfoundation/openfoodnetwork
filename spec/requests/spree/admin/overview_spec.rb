# frozen_string_literal: true

require "spec_helper"

describe "/admin", type: :request do
  let(:enterprise) { create(:supplier_enterprise, name: "Feedme") }
  let(:enterprise_user) { create(:user, enterprise_limit: 1) }

  before do
    enterprise_user.enterprise_roles.build(enterprise:).save
    sign_in enterprise_user
  end

  describe "GET /admin" do
    before do
      allow(TermsOfServiceFile).to receive(:updated_at).and_return(2.hours.ago)
    end

    it "loads the dashboard page" do
      get "/admin"

      expect(response).to render_template("spree/admin/overview/single_enterprise_dashboard")
    end

    # The banner will show on all admin page, we are just testing it here
    describe "terms of service updated banner" do
      context "when terms of service has been updated" do
        it "shows accept new ToS banner" do
          enterprise_user.update(terms_of_service_accepted_at: nil)

          get "/admin"

          expect(response.body).to include("Terms of Service have been updated")
        end

        context "when user has accepted new terms of service" do
          it "doesn't show accept new ToS banner" do
            enterprise_user.update(terms_of_service_accepted_at: 1.hour.ago)

            get "/admin"

            expect(response.body).to_not include("Terms of Service have been updated")
          end
        end

        # Shouldn't be possible
        context "when user has accepted new terms of service in the future" do
          it "shows accept new ToS banner" do
            enterprise_user.update(terms_of_service_accepted_at: 1.hour.from_now)

            get "/admin"

            expect(response.body).to include("Terms of Service have been updated")
          end
        end
      end
    end
  end
end
