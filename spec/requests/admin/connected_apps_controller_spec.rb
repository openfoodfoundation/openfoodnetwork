# frozen_string_literal: true

RSpec.describe "Admin ConnectedApp" do
  let(:user) { create(:admin_user) }
  let(:enterprise) { create(:enterprise, owner: user) }
  let(:edit_enterprise_url) { "#{edit_admin_enterprise_url(enterprise)}#/connected_apps_panel" }

  before do
    sign_in user
  end

  describe "POST /admin/enterprises/:enterprise_id/connected_apps" do
    context "with type ConnectedApps::Vine" do
      let(:vine_api) { instance_double(Vine::ApiService) }

      before do
        allow(Vine::JwtService).to receive(:new).and_return(instance_double(Vine::JwtService))
        allow(Vine::ApiService).to receive(:new).and_return(vine_api)
      end

      it "creates a new connected app" do
        allow(vine_api).to receive(:my_team).and_return(mock_api_response(true))

        params = {
          type: ConnectedApps::Vine,
          vine_api_key: "12345678",
          vine_secret: "my_secret"
        }
        post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

        vine_app = ConnectedApps::Vine.find_by(enterprise_id: enterprise.id)
        expect(vine_app).not_to be_nil
        expect(vine_app.data["api_key"]).to eq("12345678")
        expect(vine_app.data["secret"]).to eq("my_secret")
      end

      it "redirects to enterprise edit page" do
        allow(vine_api).to receive(:my_team).and_return(mock_api_response(true))

        params = {
          type: ConnectedApps::Vine,
          vine_api_key: "12345678",
          vine_secret: "my_secret"
        }
        post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

        expect(response).to redirect_to(edit_enterprise_url)
      end

      context "when api key is empty" do
        it "redirects to enterprise edit page, with an error" do
          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "",
            vine_secret: "my_secret"
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

          expect(response).to redirect_to(edit_enterprise_url)
          expect(flash[:error]).to eq("Please enter an API key and a secret")
          expect(ConnectedApps::Vine.find_by(enterprise_id: enterprise.id)).to be_nil
        end
      end

      context "when api secret is empty" do
        it "redirects to enterprise edit page, with an error" do
          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "12345678",
            vine_secret: ""
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

          expect(response).to redirect_to(edit_enterprise_url)
          expect(flash[:error]).to eq("Please enter an API key and a secret")
          expect(ConnectedApps::Vine.find_by(enterprise_id: enterprise.id)).to be_nil
        end
      end

      context "when api key or secret is not valid" do
        before do
          allow(vine_api).to receive(:my_team).and_return(mock_api_response(false))
        end

        it "doesn't create a new connected app" do
          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "12345678",
            vine_secret: "my_secret"
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

          expect(ConnectedApps::Vine.find_by(enterprise_id: enterprise.id)).to be_nil
        end

        it "redirects to enterprise edit page, with an error" do
          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "12345678",
            vine_secret: "my_secret"
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

          expect(response).to redirect_to(edit_enterprise_url)
          expect(flash[:error]).to eq(
            "An error occured when connecting to Vine API. Check you entered your API key \
            and secret correctly, contact your instance manager if the error persists".squish
          )
        end
      end

      context "when VINE API is not set up properly" do
        before do
          allow(ENV).to receive(:fetch).and_call_original
          allow(ENV).to receive(:fetch).with("VINE_API_URL").and_raise(KeyError)
          allow(Vine::ApiService).to receive(:new).and_call_original
        end

        it "redirects to enterprise edit page, with an error" do
          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "12345678",
            vine_secret: "my_secret"
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

          expect(response).to redirect_to(edit_enterprise_url)
          expect(flash[:error]).to eq(
            "VINE API is not configured, please contact your instance manager"
          )
        end

        it "notifies Bugsnag" do
          expect(Bugsnag).to receive(:notify)

          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "12345678",
            vine_secret: "my_secret"
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )
        end
      end

      context "when there is a connection error" do
        before do
          allow(vine_api).to receive(:my_team).and_raise(Faraday::Error)
        end

        it "redirects to enterprise edit page, with an error" do
          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "12345678",
            vine_secret: "my_secret"
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )

          expect(response).to redirect_to(edit_enterprise_url)
          expect(flash[:error]).to eq("API connection error, please try again")
        end

        it "notifies Bugsnag" do
          expect(Bugsnag).to receive(:notify)

          params = {
            type: ConnectedApps::Vine,
            vine_api_key: "12345678",
            vine_secret: "my_secret"
          }
          post("/admin/enterprises/#{enterprise.id}/connected_apps", params: )
        end
      end
    end

    describe "DELETE /admin/enterprises/:enterprise_id/connected_apps/:id" do
      it "deletes the connected app" do
        app = ConnectedApps::Vine.create!(enterprise:)
        delete("/admin/enterprises/#{enterprise.id}/connected_apps/#{app.id}")

        expect(ConnectedApps::Vine.find_by(enterprise_id: enterprise.id)).to be_nil
      end

      it "redirect to enterprise edit page" do
        app = ConnectedApps::Vine.create!(enterprise:,
                                          data: {
                                            api_key: "12345", secret: "my_secret"
                                          })
        delete("/admin/enterprises/#{enterprise.id}/connected_apps/#{app.id}")

        expect(response).to redirect_to(edit_enterprise_url)
      end
    end
  end

  def mock_api_response(success)
    mock_response = instance_double(Faraday::Response)
    allow(mock_response).to receive(:success?).and_return(success)
    mock_response
  end
end
