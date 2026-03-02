# frozen_string_literal: true

RSpec.describe Permissions::Order do
  let(:permissions) { described_class.new(user) }
  let!(:basic_permissions) { OpenFoodNetwork::Permissions.new(user) }
  let(:distributor) { create(:distributor_enterprise) }
  let(:coordinator) { create(:distributor_enterprise) }
  let(:order_cycle) {
    create(:simple_order_cycle, coordinator:, distributors: [distributor])
  }
  let(:order_completed) {
    create(:completed_order_with_totals, order_cycle:, distributor: )
  }
  let(:order_cancelled) {
    create(:order, order_cycle:, distributor:, state: 'canceled' )
  }
  let(:order_cart) {
    create(:order, order_cycle:, distributor:, state: 'cart' )
  }
  let(:order_from_last_year) {
    create(:completed_order_with_totals, order_cycle:, distributor:,
                                         completed_at: 1.year.ago)
  }

  before { allow(OpenFoodNetwork::Permissions).to receive(:new) { basic_permissions } }

  context "with user cannot only manage line_items in orders" do
    let(:user) do
      instance_double('Spree::User', can_manage_line_items_in_orders_only?: false, admin?: false)
    end

    describe "finding orders that are visible in reports" do
      let(:random_enterprise) { create(:distributor_enterprise) }
      let(:order) { create(:order, order_cycle:, distributor: ) }
      let!(:line_item) { create(:line_item, order:) }
      let!(:producer) { create(:supplier_enterprise) }

      before do
        allow(basic_permissions).to receive(:coordinated_order_cycles) { Enterprise.where("1=0") }
      end

      context "as the hub through which the order was placed" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: distributor)
                                      }
        end

        it "should let me see the order" do
          expect(permissions.visible_orders).to include order
        end
      end

      context "as the coordinator of the order cycle through which the order was placed" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: coordinator)
                                      }
          allow(basic_permissions).to receive(:coordinated_order_cycles) {
                                        OrderCycle.where(id: order_cycle)
                                      }
        end

        it "should let me see the order" do
          expect(permissions.visible_orders).to include order
        end

        context "with search params" do
          let(:search_params) {
            { completed_at_gt: Time.zone.now.yesterday.strftime('%Y-%m-%d') }
          }
          let(:permissions) { Permissions::Order.new(user, search_params) }

          it "only returns completed, non-cancelled orders within search filter range" do
            expect(permissions.visible_orders).to include order_completed
            expect(permissions.visible_orders).not_to include order_cancelled
            expect(permissions.visible_orders).not_to include order_cart
            expect(permissions.visible_orders).not_to include order_from_last_year
          end
        end
      end

      context "as a producer which has granted P-OC to the distributor of an order" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: producer)
                                      }
          create(:enterprise_relationship, parent: producer, child: distributor,
                                           permissions_list: [:add_to_order_cycle])
        end

        context "which contains my products" do
          before do
            line_item.variant.supplier = producer
            line_item.variant.save
          end

          it "should let me see the order" do
            expect(permissions.visible_orders).to include order
          end
        end

        context "which does not contain my products" do
          it "should not let me see the order" do
            expect(permissions.visible_orders).not_to include order
          end
        end
      end

      context "as an enterprise that is a distributor in the order cycle, " \
              "but not the distributor of the order" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: random_enterprise)
                                      }
        end

        it "should not let me see the order" do
          expect(permissions.visible_orders).not_to include order
        end
      end
    end

    describe "finding line items that are visible in reports" do
      let(:random_enterprise) { create(:distributor_enterprise) }
      let(:order) { create(:order, order_cycle:, distributor: ) }
      let!(:line_item1) { create(:line_item, order:) }
      let!(:line_item2) { create(:line_item, order:) }
      let!(:producer) { create(:supplier_enterprise) }

      before do
        allow(basic_permissions).to receive(:coordinated_order_cycles) { Enterprise.where("1=0") }
      end

      context "as the hub through which the parent order was placed" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: distributor)
                                      }
        end

        it "should let me see the line_items" do
          expect(permissions.visible_line_items).to include line_item1, line_item2
        end
      end

      context "as the coordinator of the order cycle through which the parent order was placed" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: coordinator)
                                      }
          allow(basic_permissions).to receive(:coordinated_order_cycles) {
                                        OrderCycle.where(id: order_cycle)
                                      }
        end

        it "should let me see the line_items" do
          expect(permissions.visible_line_items).to include line_item1, line_item2
        end
      end

      context "as the manager producer which has granted P-OC to the distributor " \
              "of the parent order" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: producer)
                                      }
          create(:enterprise_relationship, parent: producer, child: distributor,
                                           permissions_list: [:add_to_order_cycle])

          line_item1.variant.supplier = producer
          line_item1.variant.save
        end

        it "should let me see the line_items pertaining to variants I produce" do
          ps = permissions.visible_line_items
          expect(ps).to include line_item1
          expect(ps).not_to include line_item2
        end
      end

      context "as an enterprise that is a distributor in the order cycle, " \
              "but not the distributor of the parent order" do
        before do
          allow(basic_permissions).to receive(:managed_enterprises) {
                                        Enterprise.where(id: random_enterprise)
                                      }
        end

        it "should not let me see the line_items" do
          expect(permissions.visible_line_items).not_to include line_item1, line_item2
        end
      end

      context "with search params" do
        let!(:line_item3) { create(:line_item, order: order_completed) }
        let!(:line_item4) { create(:line_item, order: order_cancelled) }
        let!(:line_item5) { create(:line_item, order: order_cart) }
        let!(:line_item6) { create(:line_item, order: order_from_last_year) }

        let(:search_params) { { completed_at_gt: Time.zone.now.yesterday.strftime('%Y-%m-%d') } }
        let(:permissions) { Permissions::Order.new(user, search_params) }

        before do
          allow(user).to receive(:admin?) { "admin" }
        end

        it "only returns line items from completed, " \
           "non-cancelled orders within search filter range" do
          expect(permissions.visible_line_items).to include order_completed.line_items.first
          expect(permissions.visible_line_items).not_to include order_cancelled.line_items.first
          expect(permissions.visible_line_items).not_to include order_cart.line_items.first
          expect(permissions.visible_line_items)
            .not_to include order_from_last_year.line_items.first
        end
      end
    end
  end

  context "with user can only manage line_items in orders" do
    let(:producer) { create(:supplier_enterprise) }
    let(:user) do
      create(:user, enterprises: [producer])
    end
    let!(:order_by_distributor_allow_edits) do
      order = create(
        :order_with_line_items,
        distributor: create(
          :distributor_enterprise,
          enable_producers_to_edit_orders: true
        ),
        line_items_count: 1
      )
      order.line_items.first.variant.update_attribute(:supplier_id, producer.id)

      order
    end
    let!(:order_by_distributor_disallow_edits) do
      create(
        :order_with_line_items,
        distributor: create(:distributor_enterprise),
        line_items_count: 1
      )
    end
    describe "#editable_orders" do
      it "returns orders where the distributor allows producers to edit" do
        expect(permissions.editable_orders.count).to eq 1
        expect(permissions.editable_orders).to include order_by_distributor_allow_edits
      end
    end

    describe "#editable_line_items" do
      it "returns line items from orders where the distributor allows producers to edit" do
        expect(permissions.editable_line_items.count).to eq 1
        expect(permissions.editable_line_items.first.order).to eq order_by_distributor_allow_edits
      end
    end
  end
end
