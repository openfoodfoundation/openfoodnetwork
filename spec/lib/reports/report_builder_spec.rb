# frozen_string_literal: true

require 'spec_helper'

describe Reports::ReportBuilder do
  let!(:line_item1) { create(:line_item, price: 10, quantity: 1) }
  let!(:line_item2) { create(:line_item, price: 20, quantity: 2) }
  let!(:line_item3) { create(:line_item, price: 15, quantity: 3) }
  let!(:line_item4) { create(:line_item, price: 15, quantity: 4) }

  let(:report_options) { { exclude_summaries: false } }
  let(:collection) { Spree::LineItem.includes(:order) }
  let(:ordering) { [:id] }
  let(:mask_data_rules) { [] }
  let(:hide_columns) { [] }
  let(:report_object) { instance_double(Reports::ReportTemplate) }
  let(:report_rows) { [] }

  let(:service) { described_class.new(report_object) }

  before do
    allow(report_object).to receive(:report_rows) { report_rows }
    allow(report_object).to receive(:options) { report_options }
    allow(report_object).to receive(:collection) { collection }
    allow(report_object).to receive(:ordering) { ordering }
    allow(report_object).to receive(:order_subgroup)
    allow(report_object).to receive(:summary_group) { nil }
    allow(report_object).to receive(:summary_row) { [] }
    allow(report_object).to receive(:mask_data_rules) { mask_data_rules }
    allow(report_object).to receive(:hide_columns) { hide_columns }
  end

  describe "creating report data from an ActiveRecord query" do
    let(:collection) {
      Spree::LineItem.includes(:order).where(id: [line_item1.id, line_item3.id])
    }

    before do
      allow(report_object).to receive(:report_row) do |object|
        {
          id: object.id,
          order_id: object.order.id,
          price: object.price.to_i
        }
      end
    end

    it "creates formatted rows for each item" do
      expect(service.call).to eq(
        [
          { id: line_item1.id, order_id: line_item1.order.id, price: line_item1.price.to_i },
          { id: line_item3.id, order_id: line_item3.order.id, price: line_item3.price.to_i }
        ]
      )
    end
  end

  describe "ordering the data" do
    context "example sorting by :price (descending), then by :quantity (ascending)" do
      let(:ordering) { [:price!, :quantity] }

      before do
        allow(report_object).to receive(:report_row) do |object|
          {
            price: object.price.to_i,
            quantity: object.quantity
          }
        end
      end

      it "sorts by multiple given columns, in either sorting direction" do
        expect(service.call).to eq(
          [
            { price: line_item2.price.to_i, quantity: line_item2.quantity },
            { price: line_item3.price.to_i, quantity: line_item3.quantity },
            { price: line_item4.price.to_i, quantity: line_item4.quantity },
            { price: line_item1.price.to_i, quantity: line_item1.quantity },
          ]
        )
      end
    end
  end

  describe "summarising the report's data" do
    let(:summariser_class) { Reports::ReportSummariser }

    before do
      allow(report_object).to receive(:report_row) do |object|
        {
          id: object.id,
          order_id: object.order_id,
          quantity: object.quantity
        }
      end
      allow(summariser_class).to receive(:new).and_call_original
      allow(summariser_class).to receive(:call).and_call_original
    end

    it "uses ReportSummariser" do
      service.call
      expect(summariser_class).to have_received(:new)
    end
  end

  describe "removing selected columns from the output" do
    let(:ordering) { [:price!, :id] }
    let(:hide_columns) { [:price] }

    before do
      allow(report_object).to receive(:report_row) do |object|
        {
          id: object.id,
          price: object.price.to_i
        }
      end
    end

    it "can sort by columns, then remove selected columns from the output" do
      expect(service.call).to eq(
        [
          { id: line_item2.id },
          { id: line_item3.id },
          { id: line_item4.id },
          { id: line_item1.id },
        ]
      )
    end
  end

  describe "masking sensitive data with a given rule" do
    let(:mask_data_rules) {
      [{
        columns: [:price, :quantity],
        replacement: "MASKED!",
        rule: proc{ |object| object.quantity > 2 }
      }]
    }

    before do
      allow(report_object).to receive(:report_row) do |object|
        {
          id: object.id,
          price: object.price.to_i,
          quantity: object.quantity
        }
      end
    end

    it "masks specified fields based on the rule" do
      expect(service.call).to eq(
        [
          { id: line_item1.id, price: line_item1.price.to_i, quantity: line_item1.quantity },
          { id: line_item2.id, price: line_item2.price.to_i, quantity: line_item2.quantity },
          { id: line_item3.id, price: "MASKED!", quantity: "MASKED!" },
          { id: line_item4.id, price: "MASKED!", quantity: "MASKED!" },
        ]
      )
    end

    context "with multiple rules" do
      let(:mask_data_rules) {
        [
          {
           columns: [:price],
           replacement: "MASK 1",
           rule: proc{ |object| object.quantity > 2 }
          },
          {
            columns: [:quantity],
            replacement: "MASK 2",
            rule: proc{ |object| object.quantity > 3 }
          }
        ]
      }

      it "masks specified fields based on rules" do
        expect(service.call).to eq(
          [
            { id: line_item1.id, price: line_item1.price.to_i, quantity: line_item1.quantity },
            { id: line_item2.id, price: line_item2.price.to_i, quantity: line_item2.quantity },
            { id: line_item3.id, price: "MASK 1", quantity: line_item3.quantity },
            { id: line_item4.id, price: "MASK 1", quantity: "MASK 2" },
          ]
        )
      end
    end
  end
end
