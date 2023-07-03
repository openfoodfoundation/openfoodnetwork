# frozen_string_literal: true

require 'spec_helper'

module Spree
  describe TaxRate do
    describe "#match" do
      let!(:zone) { create(:zone_with_member) }
      let!(:order) { create(:order, distributor: hub, bill_address: create(:address)) }
      let!(:tax_rate) {
        create(:tax_rate, included_in_price: true,
                          calculator: ::Calculator::FlatRate.new(preferred_amount: 0.1), zone: zone)
      }

      describe "when the order's hub charges sales tax" do
        let(:hub) { create(:distributor_enterprise, charges_sales_tax: true) }

        it "selects all tax rates" do
          expect(TaxRate.match(order)).to eq([tax_rate])
        end
      end

      describe "when the order's hub does not charge sales tax" do
        let(:hub) { create(:distributor_enterprise, charges_sales_tax: false) }

        it "selects no tax rates" do
          expect(TaxRate.match(order)).to be_empty
        end
      end

      describe "when the order does not have a hub" do
        let!(:order) { create(:order, distributor: nil, bill_address: create(:address)) }

        it "selects all tax rates" do
          expect(TaxRate.match(order)).to eq([tax_rate])
        end
      end
    end

    context "original Spree::TaxRate specs" do
      context "match" do
        let(:order) { create(:order) }
        let(:country) { create(:country) }
        let(:tax_category) { create(:tax_category) }
        let(:calculator) { ::Calculator::FlatRate.new }

        it "should return an empty array when tax_zone is nil" do
          allow(order).to receive(:tax_zone) { nil }
          expect(Spree::TaxRate.match(order)).to eq []
        end

        context "when no rate zones match the tax zone" do
          before do
            Spree::TaxRate.create(amount: 1, zone: create(:zone))
          end

          context "when there is no default tax zone" do
            before do
              @zone = create(:zone, name: "Country Zone", default_tax: false, zone_members: [])
              @zone.zone_members.create(zoneable: country)
            end

            it "should return an empty array" do
              allow(order).to receive(:tax_zone) { @zone }
              expect(Spree::TaxRate.match(order)).to eq []
            end

            it "should return the rate that matches the rate zone" do
              rate = Spree::TaxRate.create(
                amount: 1,
                zone: @zone,
                tax_category: tax_category,
                calculator: calculator
              )

              allow(order).to receive(:tax_zone) { @zone }

              expect(Spree::TaxRate.match(order)).to eq [rate]
            end

            it "should return all rates that match the rate zone" do
              rate1 = Spree::TaxRate.create(
                amount: 1,
                zone: @zone,
                tax_category: tax_category,
                calculator: calculator
              )

              rate2 = Spree::TaxRate.create(
                amount: 2,
                zone: @zone,
                tax_category: tax_category,
                calculator: ::Calculator::FlatRate.new
              )

              allow(order).to receive(:tax_zone) { @zone }

              expect(Spree::TaxRate.match(order)).to eq [rate1, rate2]
            end

            context "when the tax_zone is contained within a rate zone" do
              before do
                sub_zone = create(:zone, name: "State Zone", zone_members: [])
                sub_zone.zone_members.create(zoneable: create(:state, country: country))
                allow(order).to receive(:tax_zone) { sub_zone }

                @rate = Spree::TaxRate.create(
                  amount: 1,
                  zone: @zone,
                  tax_category: tax_category,
                  calculator: calculator
                )
              end

              it "should return the rate zone" do
                expect(Spree::TaxRate.match(order)).to eq [@rate]
              end
            end
          end

          context "when there is a default tax zone" do
            before do
              @zone = create(:zone, name: "Country Zone", default_tax: true, zone_members: [])
              @zone.zone_members.create(zoneable: country)
            end

            let(:included_in_price) { false }
            let!(:rate) do
              Spree::TaxRate.create(amount: 1,
                                    zone: @zone,
                                    tax_category: tax_category,
                                    calculator: calculator,
                                    included_in_price: included_in_price)
            end

            subject { Spree::TaxRate.match(order) }

            context "when the order has the same tax zone" do
              before do
                allow(order).to receive(:tax_zone) { @zone }
                allow(order).to receive(:billing_address) { tax_address }
              end

              let(:tax_address) { build_stubbed(:address) }

              context "when the tax is not a VAT" do
                it { is_expected.to eq [rate] }
              end

              context "when the tax is a VAT" do
                let(:included_in_price) { true }
                it { is_expected.to eq [rate] }
              end
            end

            context "when the order has a different tax zone" do
              let(:other_zone) { create(:zone, name: "Other Zone") }

              before do
                allow(order).to receive(:tax_zone) { other_zone }
                allow(order).to receive(:billing_address) { tax_address }
              end

              context "when the order has a tax_address" do
                let(:tax_address) { build_stubbed(:address) }

                context "when the tax is a VAT" do
                  let(:included_in_price) { true }
                  # The rate should match in this instance because:
                  # 1) It's the default rate (and as such, a negative adjustment should apply)
                  it { is_expected.to eq [rate] }
                end

                context "when the tax is not VAT" do
                  it "returns no tax rate" do
                    expect(subject).to be_empty
                  end
                end
              end

              context "when the order does not have a tax_address" do
                let(:tax_address) { nil }

                context "when the tax is a VAT" do
                  let(:included_in_price) { true }
                  # The rate should match in this instance because:
                  # 1) The order has no tax address by this stage
                  # 2) With no tax address, it has no tax zone
                  # 3) Therefore, we assume the default tax zone
                  # 4) This default zone has a default tax rate.
                  it { is_expected.to eq [rate] }
                end

                context "when the tax is not a VAT" do
                  it { is_expected.to be_empty }
                end
              end
            end
          end
        end
      end

      context "adjust" do
        let(:order) { create(:order) }
        let(:tax_category_1) { build_stubbed(:tax_category) }
        let(:tax_category_2) { build_stubbed(:tax_category) }
        let(:rate_1) { build_stubbed(:tax_rate, tax_category: tax_category_1) }
        let(:rate_2) { build_stubbed(:tax_rate, tax_category: tax_category_2) }
        let(:line_items) { [build_stubbed(:line_item)] }

        context "with line items" do
          let(:line_item) { build_stubbed(:line_item, tax_category: tax_category_1) }
          let(:line_items) { [line_item] }

          before do
            allow(Spree::TaxRate).to receive(:match) { [rate_1, rate_2] }
          end

          it "should apply adjustments for two tax rates to the order" do
            expect(rate_1).to receive(:adjust)
            expect(rate_2).to_not receive(:adjust)
            Spree::TaxRate.adjust(order, line_items)
          end
        end

        context "with shipments" do
          let(:shipment) { build_stubbed(:shipment, order: order) }
          let(:shipments) { [shipment] }

          before do
            allow(shipment).to receive(:tax_category) { tax_category_1 }
            allow(Spree::TaxRate).to receive(:match) { [rate_1, rate_2] }
          end

          it "should apply adjustments for two tax rates to the order" do
            expect(rate_1).to receive(:adjust)
            expect(rate_2).to_not receive(:adjust)
            Spree::TaxRate.adjust(order, shipments)
          end
        end
      end

      context "default" do
        let(:tax_category) { create(:tax_category) }
        let(:country) { create(:country) }
        let(:calculator) { ::Calculator::FlatRate.new }

        context "when there is no default tax_category" do
          before { tax_category.is_default = false }

          it "should return 0" do
            expect(Spree::TaxRate.default).to eq 0
          end
        end

        context "when there is a default tax_category" do
          before { tax_category.update_column :is_default, true }

          context "when the default category has tax rates in the default tax zone" do
            before(:each) do
              allow(DefaultCountry).to receive(:id) { country.id }
              @zone = create(:zone, name: "Country Zone", default_tax: true)
              @zone.zone_members.create(zoneable: country)
              rate = Spree::TaxRate.create(
                amount: 1,
                zone: @zone,
                tax_category: tax_category,
                calculator: calculator
              )
            end

            it "should return the correct tax_rate" do
              expect(Spree::TaxRate.default.to_f).to eq 1.0
            end
          end

          context "when the default category has no tax rates in the default tax zone" do
            it "should return 0" do
              expect(Spree::TaxRate.default).to eq 0
            end
          end
        end
      end

      describe "#adjust" do
        let!(:country) { create(:country, name: "Default Country") }
        let!(:state) { create(:state, name: "Default State", country: country) }
        let!(:zone) { create(:zone_with_member, default_tax: true, member: country ) }
        let!(:category) { create(:tax_category, name: "Taxable Foo") }
        let!(:category2) { create(:tax_category, name: "Non Taxable") }
        let!(:rate1) {
          create(:tax_rate, amount: 0.10, zone: zone, tax_category: category)
        }
        let!(:rate2) {
          create(:tax_rate, amount: 0.05, zone: zone, tax_category: category)
        }
        let(:hub) { create(:distributor_enterprise, charges_sales_tax: true) }
        let(:address) { create(:address, state: country.states.first, country: country) }
        let!(:order) {
          create(:order_with_line_items, line_items_count: 2, distributor: hub,
                                         ship_address: address)
        }
        let!(:taxable) { order.line_items.first.variant }
        let!(:nontaxable) { order.line_items.last.variant }

        before do
          taxable.update(tax_category: category)
          nontaxable.update(tax_category: category2)
          order.line_items.delete_all
        end

        context "not taxable line item " do
          let!(:line_item) { order.contents.add(nontaxable, 1) }

          it "should not create a tax adjustment" do
            Spree::TaxRate.adjust(order, order.line_items)
            expect(line_item.adjustments.tax.charge.count).to eq 0
          end

          it "should not create a refund" do
            Spree::TaxRate.adjust(order, order.line_items)
            expect(line_item.adjustments.credit.count).to eq 0
          end
        end

        context "taxable line item" do
          let!(:line_item) { order.contents.add(taxable, 1) }

          before do
            rate1.update_column(:included_in_price, true)
            rate2.update_column(:included_in_price, true)
          end

          context "when price includes tax" do
            context "when zone is contained by default tax zone" do
              it "should create two adjustments, one for each tax rate" do
                Spree::TaxRate.adjust(order, order.line_items)
                expect(line_item.adjustments.count).to eq 2
              end

              it "should not create a tax refund" do
                Spree::TaxRate.adjust(order, order.line_items)
                expect(line_item.adjustments.credit.count).to eq 0
              end
            end

            context "when order's zone is neither the default zone, or included " \
                    "in the default zone, but matches the rate's zone" do
              before do
                # With no zone members, this zone will not contain anything
                zone.zone_members.delete_all
              end

              it "should create an adjustment" do
                Spree::TaxRate.adjust(order, order.line_items)
                expect(line_item.adjustments.charge.count).to eq 2
              end

              it "should not create a tax refund for each tax rate" do
                Spree::TaxRate.adjust(order, order.line_items)
                expect(line_item.adjustments.credit.count).to eq 0
              end
            end

            context "when order's zone does not match default zone, is not included in the " \
                    "default zone, AND does not match the rate's zone" do
              let!(:other_country) { create(:country, name: "Other Country") }
              let!(:other_state) { create(:state, name: "Other State", country: other_country) }
              let!(:other_address) { create(:address, state: other_state, country: other_country) }
              let!(:other_zone) {
                create(:zone_with_member, name: "Other Zone", default_tax: false,
                                          member: other_country)
              }

              before do
                order.update(ship_address: other_address)
                order.all_adjustments.delete_all
              end

              it "should not create positive adjustments" do
                Spree::TaxRate.adjust(order, order.line_items)
                expect(line_item.adjustments.charge.count).to eq 0
              end

              it "should create a tax refund for each tax rate" do
                Spree::TaxRate.adjust(order, order.line_items)
                expect(line_item.adjustments.credit.count).to eq 2
              end
            end
          end

          context "when price does not include tax" do
            before do
              allow(order).to receive(:tax_zone) { zone }
              [rate1, rate2].each do |rate|
                rate.update(included_in_price: false, zone: zone)
              end

              Spree::TaxRate.adjust(order, order.line_items)
            end

            it "should not delete adjustments for complete order when taxrate is deleted" do
              rate1.destroy!
              rate2.destroy!
              expect(line_item.adjustments.count).to eq 2
            end

            it "should create adjustments" do
              expect(line_item.adjustments.count).to eq 2
            end

            it "should not create a tax refund" do
              expect(line_item.adjustments.credit.count).to eq 0
            end

            it "should remove adjustments when tax_zone is removed" do
              expect(line_item.adjustments.count).to eq 2
              allow(order).to receive(:tax_zone) { nil }
              Spree::TaxRate.adjust(order, order.line_items)
              expect(line_item.adjustments.count).to eq 0
            end
          end
        end
      end
    end
  end
end
