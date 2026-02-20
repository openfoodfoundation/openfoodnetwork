# frozen_string_literal: true

RSpec.describe 'ProductSortByStocks' do
  let(:product) { create(:product) }

  describe 'class level SQL accessors' do
    it 'exposes SQL Arel nodes for sorting' do
      expect(Spree::Product.on_hand_sql).to be_a(Arel::Nodes::SqlLiteral)
      expect(Spree::Product.backorderable_priority_sql).to be_a(Arel::Nodes::SqlLiteral)
      expect(Spree::Product.backorderable_name_sql).to be_a(Arel::Nodes::SqlLiteral)
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

  describe 'backorderable_name ransacker behaviour' do
    it 'sorts alphabetically *only* within backorderable products' do
      stock_c = create(:product, name: "Product-C")
      bo_b = create(:product, name: "Product-B")
      bo_a = create(:product, name: "Product-A")

      # Mark only Product-A and Product-B as backorderable
      [bo_a, bo_b].each do |p|
        p.variants.first.stock_items.update_all(backorderable: true)
      end

      # Product-C stays non-backorderable
      stock_c.variants.first.stock_items.update_all(backorderable: false)

      result = Spree::Product.ransack(s: ['backorderable_priority desc',
                                          'backorderable_name asc']).result.to_a

      # backorderable products come first, alphabetically:
      #   Product-A, Product-B, then non-backorderable Product-C
      expect(result).to eq([bo_a, bo_b, stock_c])
    end

    it 'returns NULL for non-backorderable products so alphabetical ordering does NOT apply' do
      bo_z = create(:product, name: "Product-Z")
      stock_a = create(:product, name: "Product-A")

      # only Product-Z is backorderable → its name is used for sorting
      bo_z.variants.first.stock_items.update_all(backorderable: true)
      stock_a.variants.first.stock_items.update_all(backorderable: false)
      result = Spree::Product.ransack(s: ['backorderable_priority desc',
                                          'backorderable_name asc']).result.to_a

      # Product-Z (on-demand) comes before Product-A (normal stock)
      expect(result).to eq([bo_z, stock_a])
    end
  end

  describe 'combined sorting' do
    let!(:bo_a)     { create(:product, name: "Backorder-A") }
    let!(:bo_b)     { create(:product, name: "Backorder-B") }
    let!(:stock_low)  { create(:product, name: "Stock-Low") }
    let!(:stock_high) { create(:product, name: "Stock-High") }

    before do
      stock_low.variants.first.stock_items.update_all(count_on_hand: 1)
      stock_high.variants.first.stock_items.update_all(count_on_hand: 10)

      bo_a.variants.first.stock_items.update_all(count_on_hand: 5, backorderable: true)
      bo_b.variants.first.stock_items.update_all(count_on_hand: 6, backorderable: true)
    end

    it 'supports combined sorting: backorderable_priority then alphabetical then on_hand asc' do
      result = Spree::Product.ransack(
        s: [
          'backorderable_priority asc',
          'backorderable_name asc',
          'on_hand asc'
        ]
      ).result.to_a

      expect(result).to eq([stock_low, stock_high, bo_a, bo_b])
    end

    it 'supports combined sorting: backorderable_priority then alphabetical then on_hand desc' do
      result = Spree::Product.ransack(
        s: [
          'backorderable_priority desc',
          'backorderable_name asc',
          'on_hand desc'
        ]
      ).result.to_a

      # Explanation:
      #   backorderables sorted first → A, B (alphabetical still applies)
      #   then normal stock sorted by stock desc → High (10), Low (1)
      expect(result).to eq([bo_a, bo_b, stock_high, stock_low])
    end
  end
end
