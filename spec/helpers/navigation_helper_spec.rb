# frozen_string_literal: true

require 'spec_helper'

module Spree
  module Admin
    describe NavigationHelper, type: :helper do
      describe "klass_for" do
        it "returns the class when present" do
          expect(helper.klass_for('products')).to eq(Spree::Product)
        end

        it "returns a symbol when there's no available class" do
          expect(helper.klass_for('lions')).to eq(:lion)
        end

        it "returns Admin::ReportsController for reports" do
          expect(helper.klass_for('reports')).to eq(::Admin::ReportsController)
        end

        it "returns :overview for the dashboard" do
          expect(helper.klass_for('dashboard')).to eq(:overview)
        end

        it "returns Spree::Order for bulk_order_management" do
          expect(helper.klass_for('bulk_order_management')).to eq(Spree::Order)
        end

        it "returns EnterpriseGroup for group" do
          expect(helper.klass_for('group')).to eq(EnterpriseGroup)
        end

        it "returns VariantOverride for Inventory" do
          expect(helper.klass_for('Inventory')).to eq(VariantOverride)
        end
      end
    end
  end
end
