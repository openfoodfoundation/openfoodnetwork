# frozen_string_literal: true

require_relative "../swagger_helper"

RSpec.describe "SocialMedias", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user) }
  let(:enterprise) do
    create(
      :enterprise,
      id: 10_000, owner: user,
      facebook: "https://facebook.com/user",
      instagram: "https://www.instagram.com/user",
    )
  end

  before { login_as user }

  path "/api/dfc/enterprises/{enterprise_id}/social_medias/{name}" do
    get "Show social media" do
      parameter name: :enterprise_id, in: :path, type: :string
      parameter name: :name, in: :path, type: :string
      produces "application/json"

      response "200", "successful" do
        let(:enterprise_id) { enterprise.id }
        let(:name) { "facebook" }

        run_test! do
          expect(json_response).to include(
            "@id" => "http://test.host/api/dfc/enterprises/10000/social_medias/facebook",
            "dfc-b:name" => "facebook",
            "dfc-b:URL" => "https://facebook.com/user",
          )
        end
      end

      response "404", "not found" do
        let(:enterprise_id) { enterprise.id }
        let(:name) { "email_address" }

        run_test!
      end
    end
  end
end
