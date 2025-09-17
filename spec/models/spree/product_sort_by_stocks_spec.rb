# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ProductSortByStocks' do
  let(:product) { create(:product) }

  describe 'class level SQL accessors' do
    it 'exposes SQL Arel nodes for sorting' do
      expect(Spree::Product.on_hand_sql).to be_a(Arel::Nodes::SqlLiteral)
      expect(Spree::Product.backorderable_priority_sql).to be_a(Arel::Nodes::SqlLiteral)
    end
  end

  describe 'on_hand ransacker behaviour' do
    it 'can be sorted via ransack by on_hand' do
      product1 = create(:product)
      product2 = create(:product)

      product1.variants.first.stock_items.update_all(count_on_hand: 2)
      product2.variants.first.stock_items.update_all(count_on_hand: 7)

      # ransack sort key: 'on_hand asc' should put product1 before product2
      result = Spree::Product.ransack(s: 'on_hand asc').result.to_a

      expect(result.index(product1)).to be < result.index(product2)
    end
  end

  describe 'backorderable_priority ransacker behaviour' do
    it 'can be sorted via ransack by backorderable_priority' do
      product1 = create(:product)
      product2 = create(:product)

      [product1, product2].each { |p|
        p.variants.each { |v|
          v.stock_items.update_all(backorderable: false)
        }
      }
      product2.variants.first.stock_items.update_all(backorderable: true)

      result = Spree::Product.ransack(s: 'backorderable_priority desc').result.to_a

      expect(result.index(product2)).to be < result.index(product1)
    end
  end

  describe 'combined sorting' do
    # shared products for combined sorting examples
    let!(:low) { create(:product) }
    let!(:mid) { create(:product) }
    let!(:high) { create(:product) }

    it 'supports combined sorting: backorderable_priority (on-demad) then on_hand (asc)' do
      low.variants.first.stock_items.update_all(count_on_hand: 1)
      mid.variants.first.stock_items.update_all(count_on_hand: 5)
      high.variants.first.stock_items.update_all(count_on_hand: 10)

      # Make 'mid' backorderable so it sorts before 'low' in backorderable_priority asc
      mid.variants.first.stock_items.update_all(backorderable: true)

      # Controller transforms 'on_hand asc' into ['backorderable_priority asc', 'on_hand asc']
      result = Spree::Product.ransack(s: ['backorderable_priority asc',
                                          'on_hand asc']).result.to_a

      expect(result).to eq([low, high, mid])
    end

    it 'supports combined sorting: backorderable_priority (on-demand) then on_hand (desc)' do
      low.variants.first.stock_items.update_all(count_on_hand: 2)
      mid.variants.first.stock_items.update_all(count_on_hand: 6)
      high.variants.first.stock_items.update_all(count_on_hand: 9)

      # make 'mid' backorderable so with primary sort desc by backorderable_priority,
      # so mid should appear before high and low
      mid.variants.first.stock_items.update_all(backorderable: true)

      # Controller transforms 'on_hand desc' into ['backorderable_priority desc', 'on_hand desc']
      result = Spree::Product.ransack(s: ['backorderable_priority desc',
                                          'on_hand desc']).result.to_a

      expect(result).to eq([mid, high, low])
    end
  end
end
