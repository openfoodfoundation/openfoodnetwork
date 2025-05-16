# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Persons", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user, id: 10_000) }
  let(:other_user) { create(:oidc_user) }

  before { login_as user }

  path "/api/dfc/persons/{id}" do
    get "Show person" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        let(:id) { user.id }

        run_test! do
          expect(response.body).to include "dfc-b:Person"
          expect(response.body).to include "persons/10000"
        end
      end

      response "404", "not found" do
        let(:id) { other_user.id }

        run_test! do
          expect(response.body).not_to include "dfc-b:Person"
        end
      end
    end
  end
end
