# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module OrderCycleManagement
      describe Base do
        context "as a site admin" do
          subject { Base.new(user, params) }
          let(:params) { {} }

          let(:user) do
            user = create(:user)
            user.spree_roles << Spree::Role.find_or_create_by!(name: "admin")
            user
          end

          describe "fetching orders" do
            let(:customers_with_balance) { instance_double(CustomersWithBalance) }

            it 'calls the OutstandingBalance query object' do
              outstanding_balance = instance_double(OutstandingBalance, query: Spree::Order.none)
              expect(OutstandingBalance).to receive(:new).and_return(outstanding_balance)

              subject.orders
            end

            it "fetches completed orders" do
              o1 = create(:order)
              o2 = create(:order, completed_at: 1.day.ago, state: 'complete')
              expect(subject.orders).to eq([o2])
            end

            it 'fetches resumed orders' do
              order = create(:order, state: 'resumed', completed_at: 1.day.ago)
              expect(subject.orders).to eq([order])
            end

            it 'orders them by id' do
              order1 = create(:order, completed_at: 1.day.ago, state: 'complete')
              order2 = create(:order, completed_at: 2.days.ago, state: 'complete')

              expect(subject.orders.pluck(:id)).to eq([order2.id, order1.id])
            end

            it "does not show cancelled orders" do
              o1 = create(:order, state: 'canceled', completed_at: 1.day.ago)
              o2 = create(:order, state: 'complete', completed_at: 1.day.ago)
              expect(subject.orders).to eq([o2])
            end

            context "default date range" do
              it "fetches orders completed in the past month" do
                o1 = create(:order, state: 'complete', completed_at: 1.month.ago - 1.day)
                o2 = create(:order, state: 'complete', completed_at: 1.month.ago + 1.day)
                expect(subject.orders).to eq([o2])
              end
            end
          end
        end

        context "as an enterprise user" do
          let!(:user) { create(:user) }

          subject { Base.new user, {} }

          describe "fetching orders" do
            let(:supplier) { create(:supplier_enterprise) }
            let(:product) { create(:simple_product, supplier: supplier) }
            let(:order) { create(:order, completed_at: 1.day.ago) }

            it "only shows orders managed by the current user" do
              d1 = create(:distributor_enterprise)
              d1.enterprise_roles.create!(user: user)
              d2 = create(:distributor_enterprise)
              d2.enterprise_roles.create!(user: create(:user))

              o1 = create(:order, distributor: d1, state: 'complete', completed_at: 1.day.ago)
              o2 = create(:order, distributor: d2, state: 'complete', completed_at: 1.day.ago)

              expect(subject).to receive(:filter).with([o1]).and_return([o1])
              expect(subject.orders).to eq([o1])
            end

            it "does not show orders through a hub that the current user does not manage" do
              # Given a supplier enterprise with an order for one of its products
              supplier.enterprise_roles.create!(user: user)
              order.line_items << create(:line_item_with_shipment, product: product)

              # When I fetch orders, I should see no orders
              expect(subject).to receive(:filter).with([]).and_return([])
              expect(subject.orders).to eq([])
            end
          end

          describe "filtering orders" do
            let!(:orders) { Spree::Order.where(nil) }
            let!(:supplier) { create(:supplier_enterprise) }

            let!(:oc1) { create(:simple_order_cycle) }
            let!(:pm1) { create(:payment_method, name: "PM1") }
            let!(:sm1) { create(:shipping_method, name: "ship1") }
            let!(:s1) { create(:shipment_with, :shipping_method, shipping_method: sm1) }
            let!(:order1) { create(:order, shipments: [s1], order_cycle: oc1) }
            let!(:payment1) { create(:payment, order: order1, payment_method: pm1) }

            it "returns all orders sans-params" do
              expect(subject.filter(orders)).to eq(orders)
            end

            it "filters to a specific order cycle" do
              oc2 = create(:simple_order_cycle)
              order2 = create(:order, order_cycle: oc2)

              allow(subject).to receive(:params).and_return(order_cycle_id: oc1.id)
              expect(subject.filter(orders)).to eq([order1])
            end

            it "filters to a payment method" do
              pm2 = create(:payment_method, name: "PM2")
              pm3 = create(:payment_method, name: "PM3")
              order2 = create(:order, payments: [create(:payment, payment_method: pm2)])
              order3 = create(:order, payments: [create(:payment, payment_method: pm3)])

              allow(subject).to receive(:params).and_return(payment_method_in: [pm1.id, pm3.id] )
              expect(subject.filter(orders)).to match_array [order1, order3]
            end

            it "filters to a shipping method" do
              sm2 = create(:shipping_method, name: "ship2")
              sm3 = create(:shipping_method, name: "ship3")
              s2 = create(:shipment_with, :shipping_method, shipping_method: sm2)
              s3 = create(:shipment_with, :shipping_method, shipping_method: sm3)
              order2 = create(:order, shipments: [s2])
              order3 = create(:order, shipments: [s3])

              allow(subject).to receive(:params).and_return(shipping_method_in: [sm1.id, sm3.id])
              expect(subject.filter(orders)).to match_array [order1, order3]
            end

            it "should do all the filters at once" do
              allow(subject).to receive(:params).and_return(order_cycle_id: oc1.id,
                                                            shipping_method_name: sm1.name,
                                                            payment_method_name: pm1.name)
              expect(subject.filter(orders)).to eq([order1])
            end
          end

          describe '#table_rows' do
            subject { Base.new(user, params) }

            let(:distributor) { create(:distributor_enterprise) }
            before { distributor.enterprise_roles.create!(user: user) }

            context 'when the report type is payment_methods' do
              subject { PaymentMethods.new(user) }

              let!(:order) do
                create(
                  :completed_order_with_totals,
                  distributor: distributor,
                  completed_at: 1.day.ago
                )
              end

              it 'returns rows with payment information' do
                allow(subject).to receive(:unformatted_render?).and_return(true)
                expect(subject.table_rows).to eq([[
                                                   order.billing_address.firstname,
                                                   order.billing_address.lastname,
                                                   order.distributor.name,
                                                   '',
                                                   order.email,
                                                   order.billing_address.phone,
                                                   order.shipment.shipping_method.name,
                                                   nil,
                                                   order.total,
                                                   -order.total
                                                 ]])
              end
            end

            context 'when the report type is delivery' do
              subject { Delivery.new(user) }
              let!(:order) do
                create(
                  :completed_order_with_totals,
                  distributor: distributor,
                  completed_at: 1.day.ago
                )
              end

              it 'returns rows with delivery information' do
                allow(subject).to receive(:unformatted_render?).and_return(true)
                expect(subject.table_rows)
                  .to eq([[
                           order.ship_address.firstname,
                           order.ship_address.lastname,
                           order.distributor.name,
                           "",
                           "#{order.ship_address.address1} #{order.ship_address.address2} " \
                           "#{order.ship_address.city}",
                           order.ship_address.zipcode,
                           order.ship_address.phone,
                           order.shipment.shipping_method.name,
                           nil,
                           order.total,
                           -order.total,
                           false,
                           order.special_instructions
                         ]])
              end
            end
          end
        end
      end
    end
  end
end
