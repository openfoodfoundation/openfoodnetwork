# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Reporting
  module Reports
    module BulkCoop
      RSpec.describe Base do
        subject { Base.new user, params }
        let(:user) { create(:admin_user) }

        describe '#query_result' do
          let(:params) { {} }
          let(:d1) { create(:distributor_enterprise) }
          let(:oc1) { create(:simple_order_cycle) }
          let(:o1) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }
          let(:group_buy_product) { create(:product, group_buy: true) }
          let(:li1) { build(:line_item_with_shipment, variant: group_buy_product.variants.first) }

          before { o1.line_items << li1 }

          context "as a site admin" do
            context 'when searching' do
              let(:params) {
                { q: { completed_at_gt: '', completed_at_lt: '', distributor_id_in: [] } }
              }

              it "fetches completed orders" do
                o2 = create(:order, state: 'cart')
                o2.line_items << build(:line_item)
                expect(subject.table_items).to eq([li1])
              end

              it 'shows canceled orders' do
                o2 = create(:order, state: 'canceled', completed_at: 1.day.ago, order_cycle: oc1,
                                    distributor: d1)
                line_item = build(:line_item_with_shipment,
                                  variant: group_buy_product.variants.first)
                o2.line_items << line_item
                expect(subject.table_items).to include(line_item)
              end
            end

            context 'when not searching' do
              let(:params) { {} }

              it "fetches completed orders" do
                o2 = create(:order, state: 'cart')
                o2.line_items << build(:line_item)
                expect(subject.table_items).to eq([li1])
              end

              it 'shows canceled orders' do
                o2 = create(:order, state: 'canceled', completed_at: 1.day.ago, order_cycle: oc1,
                                    distributor: d1)
                line_item = build(:line_item_with_shipment,
                                  variant: group_buy_product.variants.first)
                o2.line_items << line_item
                expect(subject.table_items).to include(line_item)
              end
            end
          end

          context "filtering by group_buy" do
            let(:non_bulk_product) { create(:product, group_buy: false) }
            let(:o2) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }
            let(:non_bulk_li) do
              build(:line_item_with_shipment, variant: non_bulk_product.variants.first)
            end

            before { o2.line_items << non_bulk_li }

            context "when bulk_coop_filters feature is disabled" do
              it 'includes line items from non-group-buy products' do
                expect(subject.table_items).to include(non_bulk_li)
              end
            end

            context "when bulk_coop_filters feature is enabled", feature: :bulk_coop_filters do
              subject { SupplierReport.new user, params }

              it 'excludes line items from non-group-buy products' do
                result = subject.query_result.flatten
                expect(result).not_to include(non_bulk_li)
              end

              it 'includes line items from group-buy products' do
                result = subject.query_result.flatten
                expect(result).to include(li1)
              end
            end
          end

          context "filtering by date" do
            it do
              user = create(:admin_user)
              o2 = create(:order, completed_at: 3.days.ago, order_cycle: oc1, distributor: d1)
              li2 = build(:line_item_with_shipment, variant: group_buy_product.variants.first)
              o2.line_items << li2

              report = Base.new user, {}
              expect(report.table_items).to match_array [li1, li2]

              report = Base.new(
                user, { q: { completed_at_gt: 2.days.ago } }
              )
              expect(report.table_items).to eq([li1])

              report = Base.new(
                user, { q: { completed_at_lt: 2.days.ago } }
              )
              expect(report.table_items).to eq([li2])
            end
          end

          context "filtering by distributor" do
            it do
              user = create(:admin_user)
              d2 = create(:distributor_enterprise)
              o2 = create(:order, distributor: d2, order_cycle: oc1,
                                  completed_at: Time.zone.now)
              li2 = build(:line_item_with_shipment, variant: group_buy_product.variants.first)
              o2.line_items << li2

              report = Base.new user, {}
              expect(report.table_items).to match_array [li1, li2]

              report = Base.new(
                user, { q: { distributor_id_in: [d1.id] } }
              )
              expect(report.table_items).to eq([li1])

              report = Base.new(
                user, { q: { distributor_id_in: [d2.id] } }
              )
              expect(report.table_items).to eq([li2])
            end
          end

          context "as a manager of a supplier" do
            let!(:user) { create(:user) }
            subject { Base.new user, {} }

            let(:s1) { create(:supplier_enterprise) }

            before do
              s1.enterprise_roles.create!(user:)
            end

            context "that has granted P-OC to the distributor" do
              let(:o2) do
                create(:order, distributor: d1, completed_at: 1.day.ago,
                               bill_address: create(:address),
                               ship_address: create(:address))
              end
              let(:li2) do
                build(:line_item_with_shipment,
                      variant: create(:variant, enterprise: s1,
                                                product: create(:base_product, group_buy: true)))
              end

              before do
                o2.line_items << li2
                create(:enterprise_relationship, parent: s1, child: d1,
                                                 permissions_list: [:add_to_order_cycle])
              end

              it "shows line items supplied by my producers, with names hidden" do
                expect(subject.table_items).to eq([li2])
                expect(subject.table_items.first.order.bill_address.firstname).to eq("< Hidden >")
              end
            end

            context "that has not granted P-OC to the distributor" do
              let(:o2) do
                create(:order, distributor: d1, completed_at: 1.day.ago,
                               bill_address: create(:address),
                               ship_address: create(:address))
              end
              let(:li2) do
                build(:line_item_with_shipment, variant: create(:variant, enterprise: s1))
              end

              before do
                o2.line_items << li2
              end

              it "does not show line items supplied by my producers" do
                expect(subject.table_items).to eq([])
              end
            end
          end
        end

        describe CustomerPayments do
          describe '#query_result' do
            let(:params) { {} }
            let(:d1) { create(:distributor_enterprise) }
            let(:oc1) { create(:simple_order_cycle) }
            subject { CustomerPayments.new user, params }

            it 'returns results grouped by order without error' do
              product = create(:product, group_buy: true)
              order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
              li = build(:line_item_with_shipment, variant: product.variants.first)
              order.line_items << li

              result = subject.query_result
              expect(result.first).to include(li)
            end

            context "when bulk_coop_filters feature is disabled" do
              it 'includes orders with mixed bulk and non-bulk products' do
                bulk_product = create(:product, group_buy: true)
                non_bulk_product = create(:product, group_buy: false)
                order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
                bulk_li = build(:line_item_with_shipment, variant: bulk_product.variants.first)
                non_bulk_li = build(:line_item_with_shipment,
                                    variant: non_bulk_product.variants.first)
                order.line_items << bulk_li
                order.line_items << non_bulk_li

                result = subject.query_result
                expect(result.length).to eq(1)
                expect(result.first).to include(bulk_li, non_bulk_li)
              end

              it 'includes orders with only non-bulk products' do
                non_bulk_product = create(:product, group_buy: false)
                order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
                non_bulk_li = build(:line_item_with_shipment,
                                    variant: non_bulk_product.variants.first)
                order.line_items << non_bulk_li

                result = subject.query_result
                expect(result.length).to eq(1)
                expect(result.first).to include(non_bulk_li)
              end
            end

            context "when bulk_coop_filters feature is enabled", feature: :bulk_coop_filters do
              it 'excludes orders with only non-bulk products' do
                non_bulk_product = create(:product, group_buy: false)
                order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
                non_bulk_li = build(:line_item_with_shipment,
                                    variant: non_bulk_product.variants.first)
                order.line_items << non_bulk_li

                expect(subject.query_result).to be_empty
              end

              it 'includes all line items from orders that contain at least one bulk product' do
                bulk_product = create(:product, group_buy: true)
                non_bulk_product = create(:product, group_buy: false)
                order = create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1)
                bulk_li = build(:line_item_with_shipment, variant: bulk_product.variants.first)
                non_bulk_li = build(:line_item_with_shipment,
                                    variant: non_bulk_product.variants.first)
                order.line_items << bulk_li
                order.line_items << non_bulk_li

                result = subject.query_result
                expect(result.length).to eq(1)
                expect(result.first).to include(bulk_li, non_bulk_li)
              end
            end
          end
        end

        describe '#columns' do
          context 'when report type is bulk_coop_customer_payments' do
            subject { CustomerPayments.new user }

            it 'returns' do
              expect(subject.columns.values).to match_array(
                [
                  :order_billing_address_name,
                  :order_completed_at,
                  :customer_payments_total_cost,
                  :customer_payments_amount_owed,
                  :customer_payments_amount_paid,
                ]
              )
            end
          end
        end

        # Yes, I know testing a private method is bad practice but report's design, tighly coupling
        # makes it very hard to make things testeable without ending up in a wormwhole.
        # This is a trade-off.
        describe '#customer_payments_amount_owed' do
          let(:params) { {} }
          let(:user) { build(:user) }
          let(:order) { create(:order) }
          let!(:line_item) { create(:line_item, order: order) }

          it 'calls #new_outstanding_balance' do
            expect_any_instance_of(Spree::Order).to receive(:new_outstanding_balance)
            CustomerPayments.new(user).__send__(:customer_payments_amount_owed, [line_item])
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
