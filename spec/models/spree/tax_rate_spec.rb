# frozen_string_literal: true

RSpec.describe Spree::TaxRate do
  describe ".match" do
    let!(:zone) { create(:zone_with_member) }
    let!(:order) { create(:order, distributor: hub, bill_address: create(:address)) }
    let!(:tax_rate) {
      create(:tax_rate, included_in_price: true,
                        calculator: Calculator::FlatRate.new(preferred_amount: 0.1), zone:)
    }

    describe "when the order's hub charges sales tax" do
      let(:hub) { create(:distributor_enterprise, charges_sales_tax: true) }

      it "selects all tax rates" do
        expect(described_class.match(order)).to eq([tax_rate])
      end
    end

    describe "when the order's hub does not charge sales tax" do
      let(:hub) { create(:distributor_enterprise, charges_sales_tax: false) }

      it "selects no tax rates" do
        expect(described_class.match(order)).to be_empty
      end
    end

    describe "when the order does not have a hub" do
      let!(:order) { create(:order, distributor: nil, bill_address: create(:address)) }

      it "selects all tax rates" do
        expect(described_class.match(order)).to eq([tax_rate])
      end
    end
  end

  context "original Spree::TaxRate specs" do
    context "match" do
      let(:order) { create(:order) }
      let(:country) { create(:country) }
      let(:tax_category) { create(:tax_category) }
      let(:calculator) { Calculator::FlatRate.new }

      it "returns an empty array when tax_zone is nil" do
        allow(order).to receive(:tax_zone) { nil }
        expect(described_class.match(order)).to eq []
      end

      context "when no rate zones match the tax zone" do
        before do
          described_class.create(amount: 1, zone: create(:zone))
        end

        context "when there is no default tax zone" do
          let(:zone) { create( :zone, name: "Country Zone", default_tax: false, member: country) }

          it "returns an empty array" do
            allow(order).to receive(:tax_zone).and_return(zone)
            expect(described_class.match(order)).to eq []
          end

          it "returns the rate that matches the rate zone" do
            rate = described_class.create(
              amount: 1,
              zone:,
              tax_category:,
              calculator:
            )

            allow(order).to receive(:tax_zone).and_return(zone)

            expect(described_class.match(order)).to eq [rate]
          end

          it "returns all rates that match the rate zone" do
            rate1 = described_class.create(
              amount: 1,
              zone:,
              tax_category:,
              calculator:
            )

            rate2 = described_class.create(
              amount: 2,
              zone:,
              tax_category:,
              calculator: Calculator::FlatRate.new
            )

            allow(order).to receive(:tax_zone).and_return(zone)

            expect(described_class.match(order)).to eq [rate1, rate2]
          end

          context "when the tax_zone is contained within a rate zone" do
            let(:sub_zone) { create(:zone, name: "State Zone", member: create(:state, country:)) }

            it "returns the rate zone" do
              allow(order).to receive(:tax_zone).and_return(sub_zone)

              rate = described_class.create(
                amount: 1,
                zone:,
                tax_category:,
                calculator:
              )

              expect(described_class.match(order)).to eq [rate]
            end
          end
        end

        context "when there is a default tax zone" do
          let(:zone) { create(:zone, name: "Country Zone", default_tax: true, member: country) }
          let(:included_in_price) { false }
          let!(:rate) do
            described_class.create(amount: 1,
                                   zone:,
                                   tax_category:,
                                   calculator:,
                                   included_in_price:)
          end

          subject { described_class.match(order) }

          context "when the order has the same tax zone" do
            before do
              allow(order).to receive(:tax_zone) { zone }
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
            let(:other_zone) { create(:zone, name: "Other Zone", default_tax: false) }

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

    describe ".default" do
      let(:tax_category) { create(:tax_category) }
      let(:country) { create(:country) }
      let(:calculator) { Calculator::FlatRate.new }

      context "when there is no default tax_category" do
        before { tax_category.is_default = false }

        it "returns 0" do
          expect(described_class.default).to eq 0
        end
      end

      context "when there is a default tax_category" do
        before { tax_category.update_column :is_default, true }

        context "when the default category has tax rates in the default tax zone" do
          before(:each) do
            allow(DefaultCountry).to receive(:id) { country.id }
            zone = create(:zone, name: "Country Zone", default_tax: true, member: country)
            rate = described_class.create(
              amount: 1,
              zone:,
              tax_category:,
              calculator:
            )
          end

          it "returns the correct tax_rate" do
            expect(described_class.default.to_f).to eq 1.0
          end
        end

        context "when the default category has no tax rates in the default tax zone" do
          it "returns 0" do
            expect(described_class.default).to eq 0
          end
        end
      end
    end

    describe ".adjust" do
      let!(:country) { create(:country, name: "Default Country") }
      let!(:state) { create(:state, name: "Default State", country:) }
      let!(:zone) { create(:zone_with_member, default_tax: true, member: country ) }
      let!(:category) { create(:tax_category, name: "Taxable Foo") }
      let!(:category2) { create(:tax_category, name: "Non Taxable") }
      let!(:rate1) {
        create(:tax_rate, amount: 0.10, zone:, tax_category: category)
      }
      let!(:rate2) {
        create(:tax_rate, amount: 0.05, zone:, tax_category: category)
      }
      let(:hub) { create(:distributor_enterprise, charges_sales_tax: true) }
      let(:address) { create(:address, state: country.states.first, country:) }
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

        it "does not create a tax adjustment" do
          described_class.adjust(order, order.line_items)
          expect(line_item.adjustments.tax.charge.count).to eq 0
        end

        it "does not create a refund" do
          described_class.adjust(order, order.line_items)
          expect(line_item.adjustments.credit.count).to eq 0
        end
      end

      context "taxable line item" do
        let!(:line_item) { order.contents.add(taxable, 1) }

        before do
          rate1.update_column(:included_in_price, true)
          rate2.update_column(:included_in_price, true)
        end

        it "applies adjustments for the matching tax rates to the order" do
          line_item = build_stubbed(:line_item, tax_category: category)
          rate3 = create(:tax_rate, amount: 0.05, zone:)

          allow(described_class).to receive(:match) { [rate1, rate3] }

          expect(rate1).to receive(:adjust)
          expect(rate3).not_to receive(:adjust)

          described_class.adjust(order, [line_item])
        end

        context "when price includes tax" do
          context "when zone is contained by default tax zone" do
            it "creates two adjustments, one for each tax rate" do
              described_class.adjust(order, order.line_items)
              expect(line_item.adjustments.count).to eq 2
            end

            it "does not create a tax refund" do
              described_class.adjust(order, order.line_items)
              expect(line_item.adjustments.credit.count).to eq 0
            end
          end

          context "when order's zone is neither the default zone, or included " \
                  "in the default zone, but matches the rate's zone" do
            before do
              # Create a new default zone, so the order's zone won't match this new one
              create(:zone_with_member, default_tax: true)
            end

            it "creates an adjustment" do
              described_class.adjust(order, order.line_items)

              expect(line_item.adjustments.charge.count).to eq 2
            end

            it "does not create a tax refund for each tax rate" do
              described_class.adjust(order, order.line_items)
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

            it "does not create positive adjustments" do
              described_class.adjust(order, order.line_items)
              expect(line_item.adjustments.charge.count).to eq 0
            end

            it "creates a tax refund for each tax rate" do
              described_class.adjust(order, order.line_items)
              expect(line_item.adjustments.credit.count).to eq 2
            end
          end
        end

        context "when price does not include tax" do
          before do
            allow(order).to receive(:tax_zone) { zone }
            [rate1, rate2].each do |rate|
              rate.update(included_in_price: false, zone:)
            end

            described_class.adjust(order, order.line_items)
          end

          it "does not delete adjustments for complete order when taxrate is deleted" do
            rate1.destroy!
            rate2.destroy!
            expect(line_item.adjustments.count).to eq 2
          end

          it "creates adjustments" do
            expect(line_item.adjustments.count).to eq 2
          end

          it "does not create a tax refund" do
            expect(line_item.adjustments.credit.count).to eq 0
          end

          it "removes adjustments when tax_zone is removed" do
            expect(line_item.adjustments.count).to eq 2
            allow(order).to receive(:tax_zone) { nil }
            described_class.adjust(order, order.line_items)
            expect(line_item.adjustments.count).to eq 0
          end
        end
      end

      context "with shipments" do
        let(:shipment) { build_stubbed(:shipment, order:) }

        it "applies adjustments for two tax rates to the order" do
          rate3 = create(:tax_rate, amount: 0.05, zone:)

          allow(shipment).to receive(:tax_category) { category }
          allow(described_class).to receive(:match) { [rate1, rate3] }

          expect(rate1).to receive(:adjust)
          expect(rate3).not_to receive(:adjust)

          described_class.adjust(order, [shipment])
        end
      end
    end
  end
end
