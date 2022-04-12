# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/ModuleLength
module Reporting
  module Reports
    module BulkCoop
      describe Base do
        subject { Base.new user, params }
        let(:user) { create(:admin_user) }

        describe '#query_result' do
          let(:params) { {} }
          let(:d1) { create(:distributor_enterprise) }
          let(:oc1) { create(:simple_order_cycle) }
          let(:o1) { create(:order, completed_at: 1.day.ago, order_cycle: oc1, distributor: d1) }
          let(:li1) { build(:line_item_with_shipment) }

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
                line_item = build(:line_item_with_shipment)
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
                line_item = build(:line_item_with_shipment)
                o2.line_items << line_item
                expect(subject.table_items).to include(line_item)
              end
            end
          end

          context "filtering by date" do
            it do
              user = create(:admin_user)
              o2 = create(:order, completed_at: 3.days.ago, order_cycle: oc1, distributor: d1)
              li2 = build(:line_item_with_shipment)
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
              li2 = build(:line_item_with_shipment)
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
              s1.enterprise_roles.create!(user: user)
            end

            context "that has granted P-OC to the distributor" do
              let(:o2) do
                create(:order, distributor: d1, completed_at: 1.day.ago,
                               bill_address: create(:address),
                               ship_address: create(:address))
              end
              let(:li2) do
                build(:line_item_with_shipment, product: create(:simple_product, supplier: s1))
              end

              before do
                o2.line_items << li2
                create(:enterprise_relationship, parent: s1, child: d1,
                                                 permissions_list: [:add_to_order_cycle])
              end

              it "shows line items supplied by my producers, with names hidden" do
                expect(subject.table_items).to eq([li2])
                expect(subject.table_items.first.order.bill_address.firstname).to eq("HIDDEN")
              end
            end

            context "that has not granted P-OC to the distributor" do
              let(:o2) do
                create(:order, distributor: d1, completed_at: 1.day.ago,
                               bill_address: create(:address),
                               ship_address: create(:address))
              end
              let(:li2) do
                build(:line_item_with_shipment, product: create(:simple_product, supplier: s1))
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
          let!(:line_item) { create(:line_item) }
          let(:order) { line_item.order }

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
