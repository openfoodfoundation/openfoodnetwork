# frozen_string_literal: true

RSpec.describe Admin::EnterprisesHelper do
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
        vouchers enterprise_permissions tag_rules shop_preferences white_label users
      ]
    end

    it "lists enabled features when allowed", feature: :connected_apps do
      allow(Spree::Config).to receive(:connected_apps_enabled).and_return "discover_regen"

      user.enterprises << enterprise
      expect(visible_items.pluck(:name)).to include "connected_apps"
    end

    context "with inventory enabled", feature: :inventory do
      it "lists inventory_settings" do
        expect(visible_items.pluck(:name)).to include "inventory_settings"
      end
    end

    it "hides Connected Apps by default" do
      user.enterprises << enterprise
      expect(visible_items.pluck(:name)).not_to include "connected_apps"
    end

    it "shows Connected Apps for specific user" do
      user.enterprises << enterprise
      Flipper.enable("cqcm-dev", user)
      expect(visible_items.pluck(:name)).to include "connected_apps"
    end
  end

  describe '#enterprise_sells_options' do
    it 'returns sells options with translations' do
      expect(helper.enterprise_sells_options.map(&:first)).to eq %w[unspecified none own any]
    end
  end

  describe "#shopfront_property_options" do
    let(:distributor) { create(:distributor_enterprise) }
    let(:order_cycle) { create(:simple_order_cycle, distributors: [distributor]) }
    let(:organic) { create(:property, presentation: "Organic") }
    let(:dairy_free) { create(:property, presentation: "dairy-free") }

    before do
      product = create(:product, properties: [organic, dairy_free])
      order_cycle.exchanges.to_enterprises(distributor).outgoing.first
        .variants << product.variants.first
      create(:property, presentation: "Not distributed")
    end

    it "returns the shop's properties alphabetically, labelled as in the shopfront" do
      expect(helper.shopfront_property_options(distributor)).to eq [
        ["dairy-free", dairy_free.id], ["Organic", organic.id]
      ]
    end
  end

  describe "#translation_without_fallback" do
    let(:key) { "admin.enterprises.form.shop_preferences.shopfront_visibility.description" }

    it "returns the translation of the current locale" do
      I18n.with_locale(:en) do
        expect(helper.translation_without_fallback(key)).to start_with "Choose whether"
      end
    end

    it "doesn't fall back to English" do
      I18n.with_locale(:en_TST) do
        expect(helper.translation_without_fallback(key)).to be_nil
      end
    end
  end

  describe "#tag_groups" do
    subject { helper.tag_groups(tag_rules) }

    context "with one group" do
      let(:tag_rules) { [tag_rule] }
      let(:tag_rule) { create(:filter_products_tag_rule, preferred_customer_tags: "test") }

      it "return an array of one tag group" do
        expected = [
          {
            position: 1,
            rules: [tag_rule],
            tags: ["test"]
          }
        ]
        expect(subject.length).to eq(1)
        expect(subject).to eq(expected)
      end

      context "wiht mutiple rules" do
        let(:enterprise) { create(:enterprise) }
        let(:tag_rules) {
          create_list(:filter_products_tag_rule, 3, enterprise:, preferred_customer_tags: "good")
        }

        it "returns all the rules associated with the tag group" do
          expect(subject.length).to eq(1)

          group = subject.first
          expect(group[:rules].length).to eq(3)
          expect(group[:tags]).to eq(["good"])
        end
      end
    end

    context "with multiple group" do
      let(:tag_rules) { [tag_rule_group1, tag_rule_group2, tag_rule_group3] }
      let(:tag_rule_group1) {
        create(:filter_products_tag_rule, enterprise:, preferred_customer_tags: "group_1")
      }
      let(:tag_rule_group2) {
        create(:filter_products_tag_rule, enterprise:, preferred_customer_tags: "group_2")
      }
      let(:tag_rule_group3) {
        create(:filter_products_tag_rule, enterprise:, preferred_customer_tags: "group_3")
      }
      let(:enterprise) { create(:enterprise) }

      it "return an array of all the group" do
        expect(subject.length).to eq(3)
        expect(subject.first[:tags]).to eq(["group_1"])
        expect(subject.second[:tags]).to eq(["group_2"])
        expect(subject.third[:tags]).to eq(["group_3"])
      end

      context "with multiple rules per group" do
        let(:tag_rules) { enterprise.tag_rules }
        let!(:tag_rules_group1) {
          create_list(:filter_products_tag_rule, 3, enterprise:, preferred_customer_tags: "group_1")
        }
        let!(:tag_rules_group2) {
          create(:filter_products_tag_rule, enterprise:, preferred_customer_tags: "group_2")
        }
        let!(:tag_rules_group3) {
          create_list(:filter_products_tag_rule, 2, enterprise:, preferred_customer_tags: "group_3")
        }

        it "matches the rules with the correct group" do
          expect(subject.length).to eq(3)
          expect(subject.first[:rules].length).to eq(3)
          expect(subject.second[:rules].length).to eq(1)
          expect(subject.third[:rules].length).to eq(2)
        end
      end
    end
  end
end
