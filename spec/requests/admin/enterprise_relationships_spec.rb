# frozen_string_literal: true

RSpec.describe "/admin/enterprise_relationships" do
  let(:enterprise) { create(:supplier_enterprise, name: "Parent") }
  let(:enterprise_user) { create(:user, enterprise_limit: 1) }
  let(:child_enterprise) { create(:supplier_enterprise, name: "Child") }

  before do
    enterprise_user.enterprise_roles.build(enterprise:).save
    sign_in enterprise_user
  end

  describe "POST /admin/enterprises/" do
    it "creates a new relationshsip" do
      params = {
        enterprise_relationship: {
          parent_id: enterprise.id,
          child_id: child_enterprise.id,
          permissions_list: ["manage_products"]
        }
      }
      post(admin_enterprise_relationships_path(enterprise), params: )

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.parsed_body)
      expect(json["parent_id"]).to eq(enterprise.id)
      expect(json["child_id"]).to eq(child_enterprise.id)
      expect(json["permissions"][0]["name"]).to eq("manage_products")
    end

    context "with a parent enterprise the user doesn't manage" do
      it "returns forbidden" do
        other_enterprise = create(:supplier_enterprise)
        params = {
          enterprise_relationship: {
            parent_id: other_enterprise.id,
            child_id: child_enterprise.id,
            permissions_list: ["manage_products"]
          }
        }
        post(admin_enterprise_relationships_path(enterprise), params: )

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "with an admin user" do
      let(:admin) { create(:user, admin: true) }

      before do
        sign_in admin
      end

      it "can add permission for an enterprise they don't manage" do
        other_enterprise = create(:supplier_enterprise)

        params = {
          enterprise_relationship: {
            parent_id: other_enterprise.id,
            child_id: child_enterprise.id,
            permissions_list: ["manage_products"]
          }
        }
        post(admin_enterprise_relationships_path(enterprise), params: )

        expect(response).to have_http_status(:ok)

        relation = EnterpriseRelationship.where(parent: other_enterprise,
                                                child: child_enterprise).first
        expect(relation.permissions_list).to include("manage_products")
      end
    end

    context "when an error occurs when saving the relationship" do
      it "returs a bad request with an error message" do
        params = {
          enterprise_relationship: {
            parent_id: enterprise.id,
            child_id: -99,
            permissions_list: ["manage_products"]
          }
        }

        post(admin_enterprise_relationships_path(enterprise), params: )

        json = response.parsed_body
        expect(response).to have_http_status(:bad_request)
        expect(json["errors"]).to eq("Child must exist")
      end
    end
  end
end
