# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20210224190247_migrate_shipping_taxes'

describe MigrateShippingTaxes do
  let(:migration) { MigrateShippingTaxes.new }

  describe '#shipping_tax_category' do
    it "creates a new shipping tax category" do
      migration.shipping_tax_category

      expect(Spree::TaxCategory.last.name).to eq I18n.t(:shipping)
    end
  end

  describe '#create_shipping_tax_rates' do
    let!(:zone1) { create(:zone_with_member) }
    let!(:zone2) { create(:zone_with_member) }

    before do
      allow(migration).to receive(:instance_shipping_tax_rate) { 0.25 }
    end

    it "creates a shipping tax rate for each zone" do
      migration.create_shipping_tax_rates

      tax_rates = Spree::TaxRate.all

      expect(tax_rates.count).to eq 2
      expect(tax_rates.map(&:zone_id).uniq.sort).to eq [zone1.id, zone2.id]
      expect(tax_rates.map(&:amount).uniq).to eq [0.25]
    end
  end

  describe '#assign_to_shipping_methods' do
    let!(:shipping_method1) { create(:shipping_method) }
    let!(:shipping_method2) { create(:shipping_method) }
    let(:shipping_tax_category) { create(:tax_category) }

    before do
      allow(migration).to receive(:shipping_tax_category) { shipping_tax_category }
    end

    it "assigns the new shipping tax category to all shipping methods" do
      migration.assign_to_shipping_methods

      expect(shipping_method1.reload.tax_category).to eq shipping_tax_category
      expect(shipping_method2.reload.tax_category).to eq shipping_tax_category
    end
  end

  describe '#migrate_tax_amounts_to_adjustments' do
    let!(:zone) { create(:zone_with_member) }
    let!(:shipping_tax_category) { create(:tax_category) }
    let!(:shipping_tax_rate) {
      create(:tax_rate, zone: zone, tax_category: shipping_tax_category, name: "Shipping Tax Rate")
    }
    let(:order) { create(:completed_order_with_fees) }
    let(:shipment) { order.shipment }

    before do
      shipment.adjustments.first.update_columns(included_tax: 0.23)
      allow(order).to receive(:tax_zone) { zone }
      allow(migration).to receive(:shipping_tax_category) { shipping_tax_category }
    end

    it "migrates the shipment's tax to a tax adjustment" do
      expect(shipment.adjustments.first.included_tax).to eq 0.23
      expect(shipment.included_tax_total).to be_zero
      expect(shipment.adjustments.tax.count).to be_zero

      migration.migrate_tax_amounts_to_adjustments

      expect(shipment.reload.included_tax_total).to eq 0.23
      expect(shipment.adjustments.tax.count).to eq 1

      shipping_tax_adjustment = shipment.adjustments.tax.first

      expect(shipping_tax_adjustment.amount).to eq 0.23
      expect(shipping_tax_adjustment.originator).to eq shipping_tax_rate
      expect(shipping_tax_adjustment.source).to eq shipment
      expect(shipping_tax_adjustment.adjustable).to eq shipment
      expect(shipping_tax_adjustment.order_id).to eq order.id
      expect(shipping_tax_adjustment.included).to eq true
      expect(shipping_tax_adjustment.state).to eq "closed"
    end
  end
end
