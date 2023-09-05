# frozen_string_literal: true

require_relative "../swagger_helper"

describe "EnterpriseGroups", type: :request, swagger_doc: "dfc.yaml", rswag_autodoc: true do
  let(:user) { create(:oidc_user) }
  let(:group) { create(:enterprise_group, id: 60_000) }

  before { login_as user }

  path "/api/dfc/enterprise_groups/{id}" do
    get "Show groups" do
      parameter name: :id, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        let(:id) { group.id }

        run_test!
      end
    end
  end
end
