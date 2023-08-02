# frozen_string_literal: true

require 'spec_helper'

module Reporting
  module Reports
    module Customers
      describe Base do
        context "as a site admin" do
          let(:user) do
            user = create(:user)
            user.spree_roles << Spree::Role.find_or_create_by!(name: 'admin')
            user
          end
          subject { Base.new user, {} }

          describe "mailing list report" do
            subject { MailingList.new user, {} }

            it "returns headers for mailing_list" do
              expect(subject.table_headers).to eq(["Email", "First Name", "Last Name", "Suburb"])
            end

            it "builds a table from a list of variants" do
              order = double(:order, email: "test@test.com")
              address = double(:billing_address, firstname: "Firsty",
                                                 lastname: "Lasty", city: "Suburbia")
              allow(order).to receive(:billing_address).and_return address
              allow(subject).to receive(:query_result).and_return [order]

              expect(subject.table_rows).to eq([[
                                                 "test@test.com", "Firsty", "Lasty", "Suburbia"
                                               ]])
            end

            context "when there are multiple orders for the same customer" do
              let!(:address) {
                create(:bill_address, firstname: "Firsty",
                                      lastname: "Lasty", city: "Suburbia")
              }
              let!(:order1) {
                create(:order_with_totals_and_distribution, :completed, bill_address: address)
              }
              let!(:order2) {
                create(:order_with_totals_and_distribution, :completed, bill_address: address)
              }
              before do
                [order1, order2].each do |order|
                  order.update!(email: "test@test.com")
                end
              end
              it "returns only one row per customer" do
                expect(subject.query_result).to match_array [order1]
                expect(subject.table_rows.size).to eq(1)
                expect(subject.table_rows).to eq([[
                                                   "test@test.com", "Firsty", "Lasty", "Suburbia"
                                                 ]])
              end
            end
          end

          describe "addresses report" do
            subject { Addresses.new user, {} }

            it "returns headers for addresses" do
              expect(subject.table_headers).to eq(["First Name", "Last Name", "Billing Address",
                                                   "Email", "Phone", "Hub", "Hub Address",
                                                   "Shipping Method"])
            end

            it "builds a table from a list of variants" do
              a = create(:address)
              d = create(:distributor_enterprise)
              o = create(:order, distributor: d, bill_address: a)
              o.shipments << create(:shipment)

              allow(subject).to receive(:query_result).and_return [o]
              expect(subject.table_rows).to eq([[
                                                 a.firstname, a.lastname,
                                                 [a.address1, a.address2, a.city].join(" "),
                                                 o.email, a.phone, d.name,
                                                 [d.address.address1, d.address.address2,
                                                  d.address.city].join(" "),
                                                 o.shipping_method.name
                                               ]])
            end

            context "when there are multiple orders for the same customer" do
              let!(:a) { create(:bill_address) }
              let!(:d){ create(:distributor_enterprise) }
              let!(:sm) { create(:shipping_method, distributors: [d]) }
              let!(:o1) {
                create(:order_with_totals_and_distribution, :completed, distributor: d,
                                                                        bill_address: a,
                                                                        shipping_method: sm)
              }
              let!(:o2) {
                create(:order_with_totals_and_distribution, :completed, distributor: d,
                                                                        bill_address: a,
                                                                        shipping_method: sm)
              }
              before do
                [o1, o2].each do |order|
                  order.update!(email: "test@test.com")
                end
              end

              it "returns only one row per customer" do
                expect(subject.query_result).to match_array [o1]
                expect(subject.table_rows.size).to eq(1)
                expect(subject.table_rows)
                  .to eq([[
                           a.firstname, a.lastname,
                           [a.address1, a.address2, a.city].join(" "),
                           o1.email, a.phone, d.name,
                           [d.address.address1, d.address.address2, d.address.city].join(" "),
                           o1.shipping_method.name
                         ]])
              end

              context "orders from different hubs" do
                let!(:d2) { create(:distributor_enterprise) }
                let!(:sm2) { create(:shipping_method, distributors: [d2]) }
                let!(:o2) {
                  create(:order_with_totals_and_distribution, :completed, distributor: d2,
                                                                          bill_address: a,
                                                                          shipping_method: sm2)
                }

                it "returns one row per customer per hub" do
                  expect(subject.query_result.size).to eq(2)
                  expect(subject.table_rows.size).to eq(2)
                  expect(subject.table_rows)
                    .to eq([[
                             a.firstname, a.lastname,
                             [a.address1, a.address2, a.city].join(" "),
                             o1.email, a.phone, d.name,
                             [d.address.address1, d.address.address2, d.address.city].join(" "),
                             o1.shipping_method.name
                           ], [
                             a.firstname, a.lastname,
                             [a.address1, a.address2, a.city].join(" "),
                             o2.email, a.phone, d2.name,
                             [d2.address.address1, d2.address.address2, d2.address.city].join(" "),
                             o2.shipping_method.name
                           ]])
                end
              end

              context "orders with different shipping methods" do
                let!(:sm2) { create(:shipping_method, distributors: [d], name: "Bike") }
                let!(:o2) {
                  create(:order_with_totals_and_distribution, :completed, distributor: d,
                                                                          bill_address: a,
                                                                          shipping_method: sm2)
                }
                before do
                  o2.select_shipping_method(sm2.id)
                end

                context "when the shipping method column is being included" do
                  let(:fields_to_show) do
                    [:first_name, :last_name, :billing_address, :email, :phone, :hub, :hub_address,
                     :shipping_method]
                  end
                  subject { Addresses.new(user, { fields_to_show: fields_to_show }) }

                  it "returns one row per customer per shipping method" do
                    expect(subject.query_result.size).to eq(2)
                    expect(subject.table_rows.size).to eq(2)
                    expect(subject.table_rows).to eq(
                      [
                        [
                          a.firstname,
                          a.lastname,
                          [a.address1, a.address2, a.city].join(" "),
                          o1.email,
                          a.phone,
                          d.name,
                          [d.address.address1, d.address.address2, d.address.city].join(" "),
                          o1.shipping_method.name
                        ],
                        [
                          a.firstname,
                          a.lastname,
                          [a.address1, a.address2, a.city].join(" "),
                          o2.email,
                          a.phone,
                          d.name,
                          [d.address.address1, d.address.address2, d.address.city].join(" "),
                          sm2.name
                        ]
                      ]
                    )
                  end
                end

                context "when the shipping method column is not included in the report" do
                  let(:fields_to_show) do
                    [:first_name, :last_name, :billing_address, :email, :phone, :hub, :hub_address]
                  end
                  subject { Addresses.new(user, { fields_to_show: fields_to_show }) }

                  it "returns a single row for the customer, otherwise it would return two identical
                      rows" do
                    expect(subject.query_result.size).to eq(2)
                    expect(subject.table_rows.size).to eq(1)
                    expect(subject.table_rows).to eq(
                      [[
                        a.firstname,
                        a.lastname,
                        [a.address1, a.address2, a.city].join(" "),
                        o1.email,
                        a.phone,
                        d.name,
                        [d.address.address1, d.address.address2, d.address.city].join(" ")
                      ]]
                    )
                  end
                end
              end
            end
          end

          describe "fetching orders" do
            it "fetches completed orders" do
              o1 = create(:order)
              o2 = create(:order, completed_at: 1.day.ago)
              expect(subject.query_result).to eq([o2])
            end

            it "does not show cancelled orders" do
              o1 = create(:order, state: "canceled", completed_at: 1.day.ago)
              o2 = create(:order, completed_at: 1.day.ago)
              expect(subject.query_result).to eq([o2])
            end
          end
        end

        context "as an enterprise user" do
          let(:user) do
            user = create(:user)
            user.spree_roles = []
            user.save!
            user
          end

          subject { Base.new user, {} }

          describe "fetching orders" do
            let(:supplier) { create(:supplier_enterprise) }
            let(:product) { create(:simple_product, supplier: supplier) }
            let(:order) { create(:order, completed_at: 1.day.ago) }

            it "only shows orders managed by the current user" do
              d1 = create(:distributor_enterprise)
              d1.enterprise_roles.build(user: user).save
              d2 = create(:distributor_enterprise)
              d2.enterprise_roles.build(user: create(:user)).save

              o1 = create(:order, distributor: d1, completed_at: 1.day.ago)
              o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

              expect(subject).to receive(:filter).with([o1]).and_return([o1])
              expect(subject.query_result).to eq([o1])
            end

            it "does not show orders through a hub that the current user does not manage" do
              # Given a supplier enterprise with an order for one of its products
              supplier.enterprise_roles.build(user: user).save
              order.line_items << create(:line_item_with_shipment, product: product)

              # When I fetch orders, I should see no orders
              expect(subject).to receive(:filter).with([]).and_return([])
              expect(subject.query_result).to eq([])
            end
          end

          describe "filtering orders" do
            let(:orders) { Spree::Order.where(nil) }
            let(:supplier) { create(:supplier_enterprise) }

            it "returns all orders sans-params" do
              expect(subject.filter(orders)).to eq(orders)
            end

            it "returns orders with a specific supplier" do
              supplier = create(:supplier_enterprise)
              supplier2 = create(:supplier_enterprise)
              product1 = create(:simple_product, supplier: supplier)
              product2 = create(:simple_product, supplier: supplier2)
              order1 = create(:order)
              order2 = create(:order)
              order1.line_items << create(:line_item, product: product1)
              order2.line_items << create(:line_item, product: product2)

              allow(subject).to receive(:params).and_return(supplier_id: supplier.id)
              expect(subject.filter(orders)).to eq([order1])
            end

            it "filters to a specific distributor" do
              d1 = create(:distributor_enterprise)
              d2 = create(:distributor_enterprise)
              order1 = create(:order, distributor: d1)
              order2 = create(:order, distributor: d2)

              allow(subject).to receive(:params).and_return(distributor_id: d1.id)
              expect(subject.filter(orders)).to eq([order1])
            end

            it "filters to a specific cycle" do
              oc1 = create(:simple_order_cycle)
              oc2 = create(:simple_order_cycle)
              order1 = create(:order, order_cycle: oc1)
              order2 = create(:order, order_cycle: oc2)

              allow(subject).to receive(:params).and_return(order_cycle_id: oc1.id)
              expect(subject.filter(orders)).to eq([order1])
            end
          end
        end
      end
    end
  end
end
