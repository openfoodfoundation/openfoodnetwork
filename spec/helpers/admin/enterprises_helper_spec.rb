# frozen_string_literal: true

require "spec_helper"

describe Admin::EnterprisesHelper, type: :helper do
  let(:user) { build(:user) }

  before do
    # Enable helper to use `#can?` method.
    # We could extract this when other helper specs need it.
    allow_any_instance_of(CanCan::ControllerAdditions).to receive(:current_ability) do
      Spree::Ability.new(user)
    end
    allow(helper).to receive(:spree_current_user) { user }
  end

  describe "#enterprise_side_menu_items" do
    let(:enterprise) { build(:enterprise) }
    let(:menu_items) { helper.enterprise_side_menu_items(enterprise) }
    let(:visible_items) { menu_items.select { |i| i[:show] } }

    it "lists default items" do
      expect(visible_items.pluck(:name)).to eq %w[
        primary_details address contact social about business_details images
        vouchers enterprise_permissions inventory_settings tag_rules
        shop_preferences users white_label
      ]
    end

    it "lists enabled features", feature: :connected_apps do
      expect(visible_items.pluck(:name)).to include "connected_apps"
    end
  end
end
