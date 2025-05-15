# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "Platforms", swagger_doc: "dfc.yaml" do
  let!(:user) { create(:oidc_user) }
  let!(:enterprise) do
    create(
      :distributor_enterprise,
      id: 10_000, owner: user, name: "Fred's Farm",
    )
  end

  before { login_as user }

  path "/api/dfc/enterprises/{enterprise_id}/platforms" do
    parameter name: :enterprise_id, in: :path, type: :string

    get "List platforms with scopes" do
      produces "application/json"

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }

        run_test! do
          expect(json_response["@id"]).to eq "https://mydataserver.com/enterprises/1/platforms"
        end
      end
    end
  end
end
