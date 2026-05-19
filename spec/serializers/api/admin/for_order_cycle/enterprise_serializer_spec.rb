# frozen_string_literal: true

RSpec.describe Api::Admin::ForOrderCycle::EnterpriseSerializer do
  subject(:serialized_enterprise) {
    described_class.new(enterprise, spree_current_user:, order_cycle:, inventory_enabled:)
  }

  let(:enterprise) { create(:distributor_enterprise, name: "My enterprise") }
  let(:spree_current_user) { instance_double(Spree::User) }
  let(:order_cycle) { instance_double(OrderCycle, coordinator: enterprise) }
  let(:issue_validator_mock) {
    instance_double(OpenFoodNetwork::EnterpriseIssueValidator, issues_summary: nil)
  }
  let(:inventory_enabled) { false }

  before do
    allow(order_cycle).to receive(:prefers_product_selection_from_coordinator_inventory_only?)
      .and_return(false)
    allow(Enterprise).to receive(:managed_by).and_return([enterprise])
    allow(OpenFoodNetwork::EnterpriseIssueValidator).to receive(:new)
      .and_return(issue_validator_mock)
  end

  describe "smoke test" do
    it "returns expected data format" do
      expect(serialized_enterprise.name).to eq("My enterprise")
      expect(serialized_enterprise.issues_summary_supplier).to match(String)
      expect(serialized_enterprise.issues_summary_distributor).to be_nil
      expect(serialized_enterprise.is_primary_producer).to eq(false)
      expect(serialized_enterprise.is_distributor).to eq(true)
      expect(serialized_enterprise.sells).to eq("any")
    end
  end

  describe "issues_summary_supplier" do
    context "when no other issue" do
      it "returns No Products" do
        expect(serialized_enterprise.issues_summary_supplier).to eq("No Products")
      end

      context "whith associated products" do
        let!(:product) { create(:simple_product, supplier_id: enterprise.id) }

        it "returns nil" do
          expect(serialized_enterprise.issues_summary_supplier).to be_nil
        end

        context "with order prefers_product_selection_from_coordinator_inventory_only? enabled" do
          let!(:inventory_item) {
            create(:inventory_item, enterprise:, variant: product.variants.first, visible: false)
          }

          before do
            allow(order_cycle).to receive(
              :prefers_product_selection_from_coordinator_inventory_only?
            ).and_return(true)
          end

          it "ignores the inventory setting and return nil" do
            expect(serialized_enterprise.issues_summary_supplier).to be_nil
          end

          context "with inventory enabled" do
            let(:inventory_enabled) { true }

            it "returns No Product as the inventory item is hidden" do
              expect(serialized_enterprise.issues_summary_supplier).to eq("No Products")
            end
          end
        end
      end
    end
  end
end
