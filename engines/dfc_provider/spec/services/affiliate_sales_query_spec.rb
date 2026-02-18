# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe AffiliateSalesQuery do
  subject(:query) { described_class }

  describe ".data" do
    let(:product) { create(:simple_product, name: "Tomatoes") }
    let(:variant1) {
      product.variants.first.tap{ |v|
        v.update!(
          display_name: "Tomatoes - Roma",
          variant_unit: "weight", unit_value: 1000, variant_unit_scale: 1000 # 1kg
        )
      }
    }
    let!(:order1) { create(:order_with_totals_and_distribution, :completed, variant: variant1) }

    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.yesterday }
    let(:tomorrow) { Time.zone.tomorrow }

    before do
      # Query dates are interpreted as UTC while the spec runs in
      # Melbourne time. At noon in Melbourne, the date is the same.
      # That simplifies the spec.
      travel_to(Time.zone.today.noon)
    end

    it "returns records filtered by date" do
      # Test data creation takes time.
      # So I'm executing more tests in one `it` block here.
      # And make it simpler to call the subject many times:
      count_rows = lambda do |**args|
        query.data(order1.distributor, **args).count
      end

      # Without any filters:
      expect(count_rows.call).to eq 1

      # From today:
      expect(count_rows.call(start_date: today)).to eq 1

      # Until today:
      expect(count_rows.call(end_date: today)).to eq 1

      # Just today:
      expect(count_rows.call(start_date: today, end_date: today)).to eq 1

      # Yesterday:
      expect(count_rows.call(start_date: yesterday, end_date: yesterday)).to eq 0

      # Until yesterday:
      expect(count_rows.call(end_date: yesterday)).to eq 0

      # From tomorrow:
      expect(count_rows.call(start_date: tomorrow)).to eq 0
    end

    it "returns data" do
      labelled_row = query.label_row(query.data(order1.distributor).first)

      expect(labelled_row).to include(
        product_name: "Tomatoes",
        unit_name: "Tomatoes - Roma (1kg)",
        unit_type: "weight",
        units: 1000.to_f,
        unit_presentation: "1kg",
        price: 10.to_d,
        distributor_postcode: order1.distributor.address.zipcode,
        distributor_country: order1.distributor.address.country.name,
        supplier_postcode: variant1.supplier.address.zipcode,
        supplier_country: variant1.supplier.address.country.name,
        quantity_sold: 1,
      )
    end

    it "returns data stored in line item at time of order" do
      # Records are updated after the orders are created
      product.update! name: "Tommy toes"
      variant1.update! display_name: "Tommy toes - Roma", price: 11

      labelled_row = query.label_row(query.data(order1.distributor).first)

      expect(labelled_row).to include(
        product_name: "Tomatoes",
        unit_name: "Tomatoes - Roma (1kg)",
        price: 10.to_d, # this price is hardcoded in the line item factory.
      )
    end

    it "returns data from variant if line item doesn't have it" do
      # Old line item records (before migration 20250713110052) don't have these values stored
      order1.line_items.first.update! product_name: nil, variant_name: nil

      labelled_row = query.label_row(query.data(order1.distributor).first)

      expect(labelled_row).to include(
        product_name: "Tomatoes",
        unit_name: "Tomatoes - Roma",
      )
    end

    context "with multiple orders" do
      let!(:order2) {
        create(:order_with_totals_and_distribution, :completed, variant: product.variants.first,
                                                                distributor: order1.distributor)
      }

      it "returns data grouped by product name" do
        labelled_row = query.label_row(query.data(order1.distributor).first)

        expect(labelled_row).to include(
          product_name: "Tomatoes",
          quantity_sold: 2,
        )
      end

      context "and multiple variants" do
        let!(:order2) {
          create(:order_with_totals_and_distribution, :completed, variant: variant2,
                                                                  distributor: order1.distributor)
        }
        let(:variant2) {
          create_variant_for(product,
                             display_name: "Tomatoes - Cherry",
                             variant_unit: "weight", unit_value: 500, variant_unit_scale: 1) # 500g
        }

        it "returns data grouped by variant name" do
          labelled_data = query.data(order1.distributor).map{ |row| query.label_row(row) }

          expect(labelled_data).to include a_hash_including(
            product_name: "Tomatoes",
            unit_name: "Tomatoes - Roma (1kg)",
            quantity_sold: 1,
          )
          expect(labelled_data).to include a_hash_including(
            product_name: "Tomatoes",
            unit_name: "Tomatoes - Cherry (500g)",
            quantity_sold: 1,
            units: 500,
            unit_presentation: "500g",
            price: 10,
          )
        end
      end
    end
  end

  describe ".label_row" do
    it "converts an array to a hash" do
      row = [
        "Apples",
        "item",
        "item",
        nil,
        nil,
        15.50,
        "3210",
        "country1",
        "3211",
        "country2",
        3,
      ]
      expect(query.label_row(row)).to eq(
        {
          product_name: "Apples",
          unit_name: "item",
          unit_type: "item",
          units: nil,
          unit_presentation: nil,
          price: 15.50,
          distributor_postcode: "3210",
          distributor_country: "country1",
          supplier_postcode: "3211",
          supplier_country: "country2",
          quantity_sold: 3,
        }
      )
    end
  end

  # Create variant for product, ready to add to line item
  def create_variant_for(product, **attrs)
    variant = product.variants.first.dup
    variant.update!(
      price: 10,
      **attrs,
    )
    variant.update! on_demand: true
    variant
  end
end
