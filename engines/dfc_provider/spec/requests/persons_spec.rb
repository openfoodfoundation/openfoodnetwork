# frozen_string_literal: true

require "swagger_helper"
require DfcProvider::Engine.root.join("spec/spec_helper")

describe "Persons", type: :request, swagger_doc: "dfc-v1.7/swagger.yaml" do
  let(:user) { create(:oidc_user) }
  let(:other_user) { create(:oidc_user) }

  before { login_as user }

  path "/api/dfc-v1.7/persons/{id}" do
    get "Show person" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        let(:id) { user.id }

        run_test! do
          expect(response.body).to include "dfc-b:Person"
          expect(response.body).to include "persons/#{user.id}"
        end
      end

      response "404", "not found" do
        let(:id) { other_user.id }

        run_test! do
          expect(response.body).to_not include "dfc-b:Person"
        end
      end
    end
  end
end
