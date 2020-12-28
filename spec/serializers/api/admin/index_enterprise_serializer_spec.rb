# frozen_string_literal: true

require 'spec_helper'

describe Api::Admin::IndexEnterpriseSerializer do
  let(:enterprise) { create(:distributor_enterprise) }
  context "when spree_current_user is a manager" do
    let(:user) { create(:user) }
    before do
      user.enterprise_roles.create(enterprise: enterprise)
    end

    it "sets 'owned' to false" do
      serializer = Api::Admin::IndexEnterpriseSerializer.new enterprise, spree_current_user: user
      expect(serializer.to_json).to match "\"owned\":false"
    end
  end

  context "when spree_current_user is " do
    let(:user) { enterprise.owner }

    it "sets 'owned' to true" do
      serializer = Api::Admin::IndexEnterpriseSerializer.new enterprise, spree_current_user: user
      expect(serializer.to_json).to match "\"owned\":true"
    end
  end

  context "when spree_current_user is the owner" do
    let(:user) { create(:admin_user) }

    it "sets 'owned' to true" do
      serializer = Api::Admin::IndexEnterpriseSerializer.new enterprise, spree_current_user: user
      expect(serializer.to_json).to match "\"owned\":true"
    end
  end
end
