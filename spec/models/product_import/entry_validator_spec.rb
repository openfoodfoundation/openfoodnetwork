# frozen_string_literal: true

require 'spec_helper'

describe ProductImport::EntryValidator do
  let(:current_user) { double(:current_user) }
  let(:import_time) { double(:import_time) }
  let(:spreadsheet_data) { double(:spreadsheet_data) }
  let(:editable_enterprises) { double(:editable_enterprises) }
  let(:inventory_permissions) { double(:inventory_permissions) }
  let(:reset_counts) { double(:reset_counts) }
  let(:import_settings) { double(:import_settings) }
  let(:all_entries) { double(:all_entries) }

  let(:entry_validator) do
    described_class.new(
      current_user,
      import_time,
      spreadsheet_data,
      editable_enterprises,
      inventory_permissions,
      reset_counts,
      import_settings,
      all_entries
    )
  end

  let(:enterprise) { create(:enterprise, name: "User Enterprise") }

  let(:entry_g) do
    ProductImport::SpreadsheetEntry.new(
      unscaled_units: "500",
      units: "500",
      unit_type: "g",
      name: 'Tomato',
      enterprise: enterprise,
      enterprise_id: enterprise.id,
      producer: enterprise,
      producer_id: enterprise.id,
      distributor: enterprise,
      price: "1.0",
      on_hand: "1"
    )
  end

  let(:entry_kg) do
    ProductImport::SpreadsheetEntry.new(
      unscaled_units: "1",
      units: "1",
      unit_type: "kg",
      name: 'Potatoes',
      enterprise: enterprise,
      enterprise_id: enterprise.id,
      producer: enterprise,
      producer_id: enterprise.id,
      distributor: enterprise,
      price: "1.0",
      on_hand: "1"
    )
  end

  describe "variant validation" do
    let(:potatoes) {
      create(
        :simple_product,
        supplier: enterprise,
        on_hand: '100',
        name: 'Potatoes',
        unit_value: 1000,
        variant_unit_scale: 1000,
        variant_unit: 'weight'
      )
    }

    let(:potato_variant) do
      ProductImport::SpreadsheetEntry.new(
        unscaled_units: "1",
        units: "1",
        unit_type: "",
        variant_unit_name: "",
        name: potatoes.name,
        display_name: 'Potatoes',
        enterprise: enterprise,
        enterprise_id: enterprise.id,
        producer: enterprise,
        producer_id: enterprise.id,
      )
    end

    before do
      allow(import_settings).to receive(:dig)
      allow(spreadsheet_data).to receive(:tax_index)
      allow(spreadsheet_data).to receive(:shipping_index)
      allow(spreadsheet_data).to receive(:categories_index)
      allow(entry_validator).to receive(:enterprise_validation)
      allow(entry_validator).to receive(:tax_and_shipping_validation)
      allow(entry_validator).to receive(:variant_of_product_validation)
      allow(entry_validator).to receive(:category_validation)
      allow(entry_validator).to receive(:shipping_presence_validation)
      allow(entry_validator).to receive(:product_validation)
    end

    it "validates a product" do
      entries = [potato_variant]
      entry_validator.validate_all(entries)
      expect(potato_variant.errors.count).to eq 4
    end
  end

  describe "inventory validation" do
    before do
      allow(entry_validator).to receive(:import_into_inventory?) { true }
      allow(entry_validator).to receive(:enterprise_validation) {}
      allow(entry_validator).to receive(:producer_validation) {}
      allow(entry_validator).to receive(:variant_of_product_validation) {}
    end

    context "products exist" do
      let!(:product_g) {
        create(
          :simple_product,
          supplier: enterprise,
          on_hand: '100',
          name: 'Tomato',
          unit_value: 500,
          variant_unit_scale: 1,
          variant_unit: 'weight'
        )
      }

      let!(:product_kg) {
        create(
          :simple_product,
          supplier: enterprise,
          on_hand: '100',
          name: 'Potatoes',
          unit_value: 1000,
          variant_unit_scale: 1000,
          variant_unit: 'weight'
        )
      }

      it "validates a spreadsheet entry in g" do
        entries = [entry_g]
        entry_validator.validate_all(entries)
        expect(entries.first.errors.count).to eq(0)
      end

      it "validates a spreadsheet entry in kg" do
        entries = [entry_kg]
        entry_validator.validate_all(entries)
        expect(entries.first.errors.count).to eq(0)
      end
    end

    context "products do not exist" do
      # stub
    end
  end

  describe "enterprise validation" do
    # stub
  end

  describe "producer_validation" do
    # stub
  end
end
