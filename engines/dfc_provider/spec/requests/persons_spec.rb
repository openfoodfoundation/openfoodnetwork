# frozen_string_literal: true

require DfcProvider::Engine.root.join("spec/spec_helper")

describe "Persons", type: :request do
  let(:user) { create(:oidc_user) }
  let(:other_user) { create(:oidc_user) }

  describe :show do
    it "returns the authenticated user" do
      get person_path(user), headers: auth_header(user.uid)
      expect(response).to have_http_status :ok
      expect(response.body).to include "dfc-b:Person"
      expect(response.body).to include "persons/#{user.id}"
    end

    it "doesn't find another user" do
      get person_path(other_user), headers: auth_header(user.uid)
      expect(response).to have_http_status :not_found
      expect(response.body).to_not include "dfc-b:Person"
    end
  end
end
