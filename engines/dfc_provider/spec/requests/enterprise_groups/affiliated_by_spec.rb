# frozen_string_literal: true

require_relative "../../swagger_helper"

RSpec.describe "EnterpriseGroups::AffiliatedBy", swagger_doc: "dfc.yaml" do
  let(:user) { create(:oidc_user, id: 12_345) }
  let(:group) {
    create(
      :enterprise_group,
      id: 60_000, owner: user, name: "Sustainable Farmers", address:,
      enterprises: [enterprise],
    )
  }
  let(:address) { create(:address, id: 40_000, address1: "8 Acres Drive") }
  let(:enterprise) { create(:enterprise, id: 10_000) }
  let!(:enterprise2) { create(:enterprise, id: 10_001) }

  before { login_as user }

  path "/api/dfc/enterprise_groups/{enterprise_group_id}/affiliated_by" do
    post "Add enterprise to group" do
      consumes "application/json"

      parameter name: :enterprise_group_id, in: :path, type: :string
      parameter name: :enterprise_id, in: :body, schema: {
        example: {
          '@id': "http://test.host/api/dfc/enterprises/10001"
        }
      }

      let(:enterprise_group_id) { group.id }
      let(:enterprise_id) do |example|
        example.metadata[:operation][:parameters].second[:schema][:example]
      end

      response "201", "created" do
        run_test! do
          expect(group.enterprises.reload).to include(enterprise2)
        end
      end

      response "400", "bad request" do
        describe "with missing request body" do
          around do |example|
            # Rswag expects all required parameters to be supplied with `let`
            # but we want to send a request without the request body parameter.
            parameters = example.metadata[:operation][:parameters]
            example.metadata[:operation][:parameters] = [parameters.first]
            example.run
            example.metadata[:operation][:parameters] = parameters
          end

          run_test!
        end

        describe "with non valid enterprise uri" do
          let(:enterprise_id) { { '@id': "http://test.host/%api/dfc/enterprises/10001" } }

          run_test!
        end
      end

      response "401", "unauthorized" do
        let(:non_group_owner) { create(:oidc_user, id: 12_346) }

        before { login_as non_group_owner }

        run_test!
      end
    end
  end

  path "/api/dfc/enterprise_groups/{enterprise_group_id}/affiliated_by/{id}" do
    delete "Remove enterprise from group" do
      parameter name: :enterprise_group_id, in: :path, type: :string
      parameter name: :id, in: :path, type: :string

      let(:enterprise_group_id) { group.id }
      let(:id) { enterprise2.id }

      response "204", "no content" do
        before do
          group.enterprises << enterprise2
        end

        it "removes enterperise from group" do |example|
          expect {
            submit_request(example.metadata)
            group.reload
          }.to change { group.enterprises.count }.by(-1)
        end
      end

      response "401", "unauthorized" do
        let(:non_group_owner) { create(:oidc_user, id: 12_346) }

        before { login_as non_group_owner }

        run_test!
      end
    end
  end
end
