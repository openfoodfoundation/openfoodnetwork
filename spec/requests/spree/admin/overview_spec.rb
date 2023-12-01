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
      mocked_tos = double(TermsOfServiceFile, updated_at: 2.hours.ago)
      allow(TermsOfServiceFile).to receive(:current).and_return(mocked_tos)
      # Mock current_url so we don't have to set up a complicated TermsOfServiceFile mock
      # with attachement
      allow(TermsOfServiceFile).to receive(:current_url).and_return("tmp/tos.pdf")
    end

    it "loads the dashboard page" do
      get "/admin"

      expect(response).to render_template("spree/admin/overview/single_enterprise_dashboard")
    end

    # The banner will show on all admin page, we are just testing it here
    describe "terms of service updated banner" do
      context "when terms of service has been updated" do
        before { Spree::Config.enterprises_require_tos = true }

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

        context "when no ToS has been uploaded" do
          it "doesn't show accept new ToS banner" do
            allow(TermsOfServiceFile).to receive(:current).and_return(nil)

            get "/admin"

            expect(response.body).to_not include("Terms of Service have been updated")
          end
        end

        context "when enterprises don't need to accept ToS" do
          before do
            Spree::Config.enterprises_require_tos = false
            enterprise_user.update(terms_of_service_accepted_at: nil)
          end

          it "doesn't show accept new ToS banner" do
            get "/admin"

            expect(response.body).to_not include("Terms of Service have been updated")
          end
        end
      end
    end
  end
end
