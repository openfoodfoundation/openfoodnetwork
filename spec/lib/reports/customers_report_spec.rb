# frozen_string_literal: true

RSpec.describe Reporting::Reports::Customers::Base do
  context "as a site admin" do
    let(:user) { create(:admin_user) }
    subject { described_class.new user, {} }

    describe "addresses report" do
      it "returns headers for addresses" do
        expect(subject.table_headers).to eq(["First Name", "Last Name", "Billing Address",
                                             "Email", "Phone", "Hub", "Hub Address",
                                             "Shipping Method", "Total Number of Orders",
                                             "Total incl. tax ($)",
                                             "Last completed order date"])
      end

      it "builds a table from a list of variants" do
        a = create(:address)
        d = create(:distributor_enterprise)
        o = create(:order, distributor: d, bill_address: a)
        o.shipments << create(:shipment)

        allow(subject).to receive(:query_result).and_return [[o]]
        expect(subject.table_rows).to eq([[
                                           a.firstname, a.lastname,
                                           [a.address1, a.address2, a.city].join(" "),
                                           o.email, a.phone, d.name,
                                           [d.address.address1, d.address.address2,
                                            d.address.city].join(" "),
                                           o.shipping_method.name, 1, o.total, "none"
                                         ]])
      end

      context "when there are multiple orders for the same customer" do
        let!(:a) { create(:bill_address) }
        let!(:d){ create(:distributor_enterprise) }
        let!(:sm) { create(:shipping_method, distributors: [d]) }
        let!(:customer) { create(:customer) }
        let!(:o1) {
          create(:order_with_totals_and_distribution, :completed, distributor: d,
                                                                  bill_address: a,
                                                                  shipping_method: sm,
                                                                  customer:)
        }
        let!(:o2) {
          create(:order_with_totals_and_distribution, :completed, distributor: d,
                                                                  bill_address: a,
                                                                  shipping_method: sm,
                                                                  customer:)
        }
        before do
          o1.update(completed_at: "2023-01-01")
          o2.update(completed_at: "2023-01-02")
          [o1, o2].each do |order|
            order.update!(email: "test@test.com")
          end
        end

        it "returns only one row per customer with the right data" do
          expect(subject.query_result).to match_array [[o1, o2]]
          expect(subject.table_rows.size).to eq(1)
          expect(subject.table_rows)
            .to eq([[
                     a.firstname, a.lastname,
                     [a.address1, a.address2, a.city].join(" "),
                     o1.email, a.phone, d.name,
                     [d.address.address1, d.address.address2, d.address.city].join(" "),
                     o1.shipping_method.name, 2, o1.total + o2.total, "2023-01-02"
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
                       o1.shipping_method.name, 1, o1.total, "2023-01-01"
                     ], [
                       a.firstname, a.lastname,
                       [a.address1, a.address2, a.city].join(" "),
                       o2.email, a.phone, d2.name,
                       [d2.address.address1, d2.address.address2, d2.address.city].join(" "),
                       o2.shipping_method.name, 1, o2.total, "2023-01-02"
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
               :shipping_method, :total_orders, :total_incl_tax, :last_completed_order_date]
            end
            subject { described_class.new(user, { fields_to_show: }) }

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
                    o1.shipping_method.name, 1, o1.total, o1.completed_at.strftime("%Y-%m-%d")
                  ],
                  [
                    a.firstname,
                    a.lastname,
                    [a.address1, a.address2, a.city].join(" "),
                    o2.email,
                    a.phone,
                    d.name,
                    [d.address.address1, d.address.address2, d.address.city].join(" "),
                    sm2.name, 1, o2.total, o2.completed_at.strftime("%Y-%m-%d")
                  ]
                ]
              )
            end
          end

          context "when the shipping method column is not included in the report" do
            let(:fields_to_show) do
              [:first_name, :last_name, :billing_address, :email, :phone, :hub, :hub_address]
            end
            subject { described_class.new(user, { fields_to_show: }) }

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
        expect(subject.query_result).to eq([[o2]])
      end

      it "does not show cancelled orders" do
        o1 = create(:order, state: "canceled", completed_at: 1.day.ago)
        o2 = create(:order, completed_at: 1.day.ago)
        expect(subject.query_result).to eq([[o2]])
      end
    end
  end

  context "as an enterprise user" do
    let(:user) { create(:user) }

    subject { described_class.new user, {} }

    describe "fetching orders" do
      let(:supplier) { create(:supplier_enterprise) }
      let(:product) { create(:simple_product, supplier_id: supplier.id) }
      let(:order) { create(:order, completed_at: 1.day.ago) }

      it "only shows orders managed by the current user" do
        d1 = create(:distributor_enterprise)
        d1.enterprise_roles.build(user:).save
        d2 = create(:distributor_enterprise)
        d2.enterprise_roles.build(user: create(:user)).save

        o1 = create(:order, distributor: d1, completed_at: 1.day.ago)
        o2 = create(:order, distributor: d2, completed_at: 1.day.ago)

        expect(subject).to receive(:filter).with([o1]).and_return([o1])
        expect(subject.query_result).to eq([[o1]])
      end

      it "does not show orders through a hub that the current user does not manage" do
        # Given a supplier enterprise with an order for one of its products
        supplier.enterprise_roles.build(user:).save
        order.line_items << create(:line_item_with_shipment, product:)

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

      describe "filters to a specific completed_at date range" do
        let!(:o1) { create(:order, completed_at: 1.day.ago) }
        let!(:o2) { create(:order, completed_at: 3.days.ago) }
        let!(:o3) { create(:order, completed_at: 5.days.ago) }

        it do
          allow(subject).to receive(:params).and_return(
            q: {
              completed_at_gt: 1.day.before(o2.completed_at),
              completed_at_lt: 1.day.after(o2.completed_at)
            }
          )
          expect(subject.filter(orders)).to eq([o2])
        end

        it "when completed_at_gt param is missing" do
          allow(subject).to receive(:params).and_return(
            q: {
              completed_at_gt: "",
              completed_at_lt: 1.day.after(o2.completed_at)
            }
          )
          expect(subject.filter(orders)).to match_array [o2, o3]
        end

        it "when completed_at_lt param is missing" do
          allow(subject).to receive(:params).and_return(
            q: {
              completed_at_gt: 1.day.before(o2.completed_at),
              completed_at_lt: ""
            }
          )
          expect(subject.filter(orders)).to match_array [o1, o2]
        end
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
