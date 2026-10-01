# frozen_string_literal: true

RSpec.describe "/admin/oauth_applications" do
  let(:admin) { create(:admin_user) }
  let!(:application) { create(:oauth_application, name: "Delivery planner") }

  context "as a super admin" do
    before { sign_in admin }

    it "lists applications" do
      get admin_oauth_applications_path

      expect(response).to have_http_status :ok
      expect(response.body).to include "Delivery planner"
    end

    it "is linked from the configuration menu" do
      get spree.edit_admin_general_settings_path

      expect(response.body).to include admin_oauth_applications_path
    end

    it "creates an application" do
      expect {
        post admin_oauth_applications_path, params: {
          oauth_application: {
            name: "Stock sync",
            redirect_uri: "https://sync.example.com/callback",
            confidential: "1",
          }
        }
      }.to change { Doorkeeper::Application.count }.by(1)

      created = Doorkeeper::Application.last
      expect(response).to redirect_to edit_admin_oauth_application_path(created)
      expect(created.name).to eq "Stock sync"
      expect(created.uid).to be_present
      expect(created.secret).to be_present
    end

    it "shows the form again with errors on invalid input" do
      post admin_oauth_applications_path, params: {
        oauth_application: { name: "", redirect_uri: "not a uri" }
      }

      expect(response).to have_http_status :unprocessable_entity
      expect(response).to render_template "admin/oauth_applications/new"
    end

    it "shows the credentials" do
      get edit_admin_oauth_application_path(application)

      expect(response.body).to include application.uid
      expect(response.body).to include application.secret
    end

    it "updates an application" do
      patch admin_oauth_application_path(application), params: {
        oauth_application: { name: "Route planner" }
      }

      expect(response).to redirect_to admin_oauth_applications_path
      expect(application.reload.name).to eq "Route planner"
    end

    it "deletes an application and its tokens" do
      Doorkeeper::AccessToken.create!(application:, resource_owner_id: admin.id)

      expect {
        delete admin_oauth_application_path(application)
      }.to change { Doorkeeper::Application.count }.by(-1)
        .and change { Doorkeeper::AccessToken.count }.by(-1)

      expect(response).to redirect_to admin_oauth_applications_path
    end
  end

  context "as an enterprise user" do
    let(:enterprise_user) { create(:user) }

    before { sign_in enterprise_user }

    it "denies access" do
      get admin_oauth_applications_path

      expect(response).to redirect_to unauthorized_path
    end
  end
end
