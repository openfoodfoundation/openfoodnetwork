describe Api::Admin::IndexEnterpriseSerializer do
  include AuthenticationWorkflow

  let(:enterprise) { create(:distributor_enterprise) }
  context "when spree_current_user is a manager" do
    let(:user) { create_enterprise_user }
    before do
      user.enterprise_roles.create(enterprise: enterprise)
    end

    it "sets 'owned' to false" do
      serializer = Api::Admin::IndexEnterpriseSerializer.new enterprise, spree_current_user: user
      serializer.to_json.should match "\"owned\":false"
    end
  end

  context "when spree_current_user is " do
    let(:user) { enterprise.owner }

    it "sets 'owned' to true" do
      serializer = Api::Admin::IndexEnterpriseSerializer.new enterprise, spree_current_user: user
      serializer.to_json.should match "\"owned\":true"
    end
  end

  context "when spree_current_user is the owner" do
    let(:user) { create(:admin_user) }

    it "sets 'owned' to true" do
      serializer = Api::Admin::IndexEnterpriseSerializer.new enterprise, spree_current_user: user
      serializer.to_json.should match "\"owned\":true"
    end
  end
end
