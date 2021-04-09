class RemoveBrokenVariantsFromCarts < ActiveRecord::Migration[4.2]
  def up
    # Removes line_items from open carts where the variant has a hard-deleted price

    variants_without_prices = execute(
      'SELECT spree_variants.id FROM spree_variants
      LEFT OUTER JOIN spree_prices ON (spree_variants.id = spree_prices.variant_id)
      WHERE spree_prices.id IS NULL'
    ).to_a.map{ |v| v['id'] }

    broken_line_items = Spree::LineItem.
      joins(:variant).where('spree_variants.id IN (?)', variants_without_prices).
      joins(:order).merge(Spree::Order.where(state: 'cart'))

    broken_line_items.each(&:destroy)
  end
end
