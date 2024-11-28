# frozen_string_literal: true

require 'spec_helper'
require_relative '../../db/migrate/20241011071014_update_item_name_to_product_in_od_report'

RSpec.describe UpdateItemNameToProductInOdReport, type: :migration do
  let!(:report_option_without_item_name_product) do
    create(
      :orders_and_distributors_options,
      options: { fields_to_show: ['other_field'] }
    )
  end

  describe '#up' do
    let!(:report_option_with_item_name) do
      create(
        :orders_and_distributors_options,
        options: { fields_to_show: ['item_name', 'other_field'] }
      )
    end
    before { subject.up }

    it 'updates fields_to_show from item_name to product only if options have item_name' do
      report_option_with_item_name.reload
      expect(fields_to_show(report_option_with_item_name)).to eq(['other_field', 'product'])
      expect(fields_to_show(report_option_without_item_name_product)).to eq(['other_field'])
    end
  end

  describe '#down' do
    let!(:report_option_with_product) do
      create(
        :orders_and_distributors_options,
        options: { fields_to_show: ['product', 'other_field'] }
      )
    end
    before { subject.down }

    it 'reverts fields_to_show from product to item_name only if options have product' do
      report_option_with_product.reload
      expect(fields_to_show(report_option_with_product)).to eq(['other_field', 'item_name'])
      expect(fields_to_show(report_option_without_item_name_product)).to eq(['other_field'])
    end
  end

  def fields_to_show(report_options)
    report_options.options[:fields_to_show]
  end
end
