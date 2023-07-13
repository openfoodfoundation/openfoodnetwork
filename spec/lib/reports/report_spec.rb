# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable Metrics/ModuleLength
module Reporting
  describe ReportTemplate do
    let(:user) { create(:user) }
    let(:params) { {} }
    subject { described_class.new(user, params) }

    # rubocop:disable Metrics/AbcSize
    def check_report
      # Mock using instance variables
      allow(subject).to receive(:columns).and_return(@columns)
      allow(subject).to receive(:query_result).and_return(@query_result)
      allow(subject).to receive(:rules).and_return(@rules) if @rules.present?
      if @custom_headers.present?
        allow(subject).to receive(:custom_headers).and_return(@custom_headers)
      end

      # Check result depending on existing instance variables
      expect(subject.rows.map(&:to_h)).to eq(@expected_rows) if @expected_rows.present?
      expect(subject.table_rows).to eq(@expected_table_rows) if @expected_table_rows.present?
      expect(subject.table_headers).to eq(@expected_headers) if @expected_headers.present?
    end
    # rubocop:enable Metrics/AbcSize

    describe ".default_params" do
      it "use correctly the default values" do
        default_params = {
          filter: "default__filter",
          other_filter: "default_other_filter",
          q: { hub: "default_hub", customer: "default_customer" }
        }
        real_params = {
          filter: "test_filter",
          q: { hub: "test_hub" }
        }
        expected_params = {
          filter: "test_filter",
          other_filter: "default_other_filter",
          q: { hub: "test_hub", customer: "default_customer" }
        }
        allow_any_instance_of(described_class).to receive(:default_params)
          .and_return(default_params)
        report = described_class.new(user, real_params)
        expect(report.params).to eq(expected_params)
      end
    end

    describe ".columns" do
      before do
        @query_result = [
          OpenStruct.new(hub: { name: "My Hub" }, product: { name: "Apple", price: 5 })
        ]
      end

      it "handle procs" do
        @columns = {
          hub: proc { |item| item.hub[:name] }
        }
        @expected_rows = [
          { hub: "My Hub" }
        ]
        check_report
      end

      it "handles symbols" do
        @columns = {
          hub: :hub_name
        }
        allow(subject).to receive(:hub_name).and_return("Transformed Hub Name")
        @expected_rows = [
          { hub: "Transformed Hub Name" }
        ]
        check_report
      end
    end

    describe ".table_headers" do
      before do
        @columns = {
          hub: proc { |item| item.hub[:name] },
          product: proc { |item| item.product[:name] },
          price: proc { |item| item.product[:price] },
        }
      end

      it "uses the columns keys" do
        @expected_headers = ['Hub', 'Product', 'Price']
        check_report
      end

      it "handles custom_headers" do
        @custom_headers = {
          product: 'Custom Product',
          not_existing_key: "My Key"
        }
        @expected_headers = ['Hub', 'Custom Product', 'Price']
        check_report
      end

      describe "fields_to_show" do
        let(:params) { { fields_to_show: [:hub, :price] } }

        it "works" do
          @expected_headers = ['Hub', 'Price']
          check_report
        end
      end
    end

    describe ".table_rows" do
      before do
        @columns = {
          price: proc { |item| item.product[:price] },
          hub: proc { |item| item.hub[:name] }
        }
        @query_result = [
          OpenStruct.new(hub: { name: "My Hub" }, product: { name: "Apple", price: 5 }),
          OpenStruct.new(hub: { name: "My Other Hub" }, product: { name: "Apple", price: 12 })
        ]
      end

      it "get correct data" do
        allow(subject).to receive(:unformatted_render?).and_return(true)
        @expected_table_rows = [
          [5, "My Hub"],
          [12, "My Other Hub"],
        ]
        check_report
      end

      context "when report contains duplicate rows" do
        before do
          @columns = {
            customer: proc { |item| item.customer },
            address: proc { |item| item.address }
          }
          @query_result = [
            OpenStruct.new(customer: "John", address: "1 Main Street"),
            OpenStruct.new(customer: "John", address: "1 Main Street")
          ]
        end

        context "and the report type allows duplicate rows i.e. the default behaviour" do
          it "outputs duplicate rows" do
            @expected_table_rows = [
              ["John", "1 Main Street"],
              ["John", "1 Main Street"]
            ]
            check_report
          end
        end

        context "and the report type does not allow duplicate rows" do
          before { allow(subject).to receive(:skip_duplicate_rows?).and_return(true) }

          it "outputs only unique rows" do
            @expected_table_rows = [
              ["John", "1 Main Street"]
            ]
            check_report
          end
        end
      end
    end

    describe ".rules" do
      describe "#group_by" do
        before do
          @columns = {
            hub: proc { |item| item.hub },
            customer: proc { |item| item.customer },
            product: proc { |item| item.product },
            quantity: proc { |item| item.quantity },
          }
          @query_result = [
            OpenStruct.new(hub: "Hub 1", customer: "John", product: "Apple", quantity: 4),
            OpenStruct.new(hub: "Hub 2", customer: "John", product: "Pear", quantity: 3),
            OpenStruct.new(hub: "Hub 2", customer: "John", product: "Apple", quantity: 5),
            OpenStruct.new(hub: "Hub 1", customer: "Abby", product: "Orange", quantity: 6),
          ]
        end

        it "works with symbol or proc" do
          @rules = [
            { group_by: proc { |_i, row| row.hub }, fields_used_in_header: [:hub], header: true },
            { group_by: :customer, header: true }
          ]
          allow(subject).to receive(:display_header_row?).and_return(true)
          @expected_rows = [
            { header: "Hub 1" },
            { header: "Abby" },
            { product: "Orange", quantity: 6 },
            { header: "John" },
            { product: "Apple", quantity: 4 },
            { header: "Hub 2" },
            { header: "John" },
            { product: "Pear", quantity: 3 },
            { product: "Apple", quantity: 5 },
          ]
          check_report
        end
      end

      describe "#sort_by" do
        before do
          @columns = {
            hub_name: proc { |item| item.hub[:name] }
          }
          hub1 = { name: "Hub 1", popularity: 5 }
          hub2 = { name: "Hub 2", popularity: 2 }
          @query_result = [
            OpenStruct.new(hub: hub2),
            OpenStruct.new(hub: hub1)
          ]
        end

        it "use default sort" do
          @rules = [{
            group_by: proc { |item, _row| item.hub }
          }]
          @expected_rows = [
            { hub_name: "Hub 1" },
            { hub_name: "Hub 2" },
          ]
          check_report
        end

        it "use sort_by proc" do
          @rules = [{
            group_by: proc { |item, _row| item.hub },
            sort_by: proc { |hub| hub[:popularity] }
          }]
          @expected_rows = [
            { hub_name: "Hub 2" },
            { hub_name: "Hub 1" }
          ]
          check_report
        end
      end

      describe "#summary_row" do
        before do
          @query_result = [
            OpenStruct.new(hub: "Hub 1", customer: "John", product: "Apple", quantity: 4),
            OpenStruct.new(hub: "Hub 2", customer: "John", product: "Pear", quantity: 3),
            OpenStruct.new(hub: "Hub 2", customer: "John", product: "Apple", quantity: 5),
            OpenStruct.new(hub: "Hub 1", customer: "Abby", product: "Orange", quantity: 6),
          ]
        end

        it "groups and sum" do
          @columns = {
            hub: proc { |item| item.hub },
            quantity: proc { |item| item.quantity },
            count: proc { |_item| "" },
          }
          @rules = [{
            group_by: :hub,
            summary_row: proc do |group_key, items, rows|
              { count: "#{group_key} count=#{items.count}", quantity: rows.sum(&:quantity) }
            end,
            summary_row_label: "TOTAL"
          }]
          @expetec_rows = [
            { hub: "Hub 1", quantity: 4, count: "" },
            { hub: "Hub 1", quantity: 6, count: "" },
            { hub: "TOTAL", quantity: 10, count: "Hub 1 count=2" },
            { hub: "Hub 2", quantity: 3, count: "" },
            { hub: "Hub 2", quantity: 5, count: "" },
            { hub: "TOTAL", quantity: 8, count: "Hub 2 count=2" }
          ]
          check_report
        end
      end

      describe "should not group when for JSON" do
        before do
          @query_result = [
            OpenStruct.new(hub: "Hub 1", customer: "John", quantity: 4)
          ]
          @columns = {
            hub: proc { |item| item.hub },
            customer: proc { |item| item.customer },
            quantity: proc { |item| item.quantity },
          }
          @rules = [{
            group_by: :hub,
            header: true,
            summary_row: proc do |_group_key, _items, rows|
              { quantity: rows.sum(&:quantity) }
            end
          }]
        end

        describe "for fields_to_show" do
          let(:params) { { fields_to_show: [:hub, :quantity], report_format: 'json' } }

          it "works" do
            @expetec_rows = [
              { hub: "Hub 1", quantity: 4 }
            ]
            check_report
          end
        end

        describe "for fields_to_hide" do
          let(:params) { { fields_to_hide: [:customer], report_format: 'json' } }

          it "works" do
            @expetec_rows = [
              { hub: "Hub 1", quantity: 4 }
            ]
            check_report
          end
        end
      end
    end
  end
end
# rubocop:enable Metrics/ModuleLength
