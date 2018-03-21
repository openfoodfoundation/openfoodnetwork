# We have duplicate price rows on Aus production
#
#     openfoodweb_production=> select * from spree_prices where variant_id = 6385;
#       id  | variant_id | amount | currency
#     ------+------------+--------+----------
#      8747 |       6385 |  19.50 | AUD
#      8746 |       6385 |   8.00 | AUD
#     (2 rows)
#
# See: https://github.com/openfoodfoundation/openfoodnetwork/issues/2151
#
# Before we run this migration, we want to tell affected enterprises about orders with potentially wrong pricing.
# SQL to list shop and order number:
#
#   select distinct(e.name, o.number) from enterprises e, spree_variants v, spree_orders o where o.distributor_id=e.id and o.id in (select order_id from spree_line_items where order_id in (select id from spree_orders where completed_at > '2018-03-02') and variant_id in (select p1.variant_id from spree_prices p1 join spree_prices p2 on p1.variant_id=p2.variant_id and p1.id!=p2.id where p1.amount!=p2.amount and p1.currency = p2.currency));
#
# SQL to list shop, product, price an item got sold for and the other price:
#
#   select distinct e.name, p.name product, v.display_name variant, i.price sold_for, pr.amount other_price from spree_products p join spree_variants v on p.id=v.product_id and v.is_master='f' join spree_line_items i on i.variant_id=v.id join spree_orders o on i.order_id=o.id join enterprises e on o.distributor_id=e.id join spree_prices pr on v.id=pr.variant_id and i.price!=pr.amount and i.currency=pr.currency where order_id in (select id from spree_orders where completed_at > '2018-03-02') and i.variant_id in (select p1.variant_id from spree_prices p1 join spree_prices p2 on p1.variant_id=p2.variant_id and p1.id!=p2.id where p1.amount!=p2.amount and p1.currency = p2.currency) order by e.name;
#
# And the SQL to list producer, product and both prices:
#
#   select p1.variant_id from spree_prices p1 join spree_prices p2 on p1.variant_id=p2.variant_id and p1.id!=p2.id and p1.amount!=p2.amount and p1.currency = p2.currency
class DeleteDuplicatePrices < ActiveRecord::Migration
  class Price < ActiveRecord::Base
    self.table_name = 'spree_prices'
  end

  OldPrice = Struct.new(:row) do
    def method_missing(name)
      value = row[name.to_s]
      return nil if value.nil?
      return value.to_i if name =~ /id/
      return value.to_f if name =~ /amount/
      super
    end
  end

  DUPLICATES_FILE = "duplicate_prices_removed_by_migration.json"
  CONFLICTS_FILE = "conflicting_prices_removed_by_migration.json"

  def up
    remove_duplicate_prices
    remove_conflicting_prices
  end

  def down
    restore_duplicate_prices
    restore_conflicting_prices
  end

  # We have a lot of price duplicates.
  # They have the same amount and currency for the same variant.
  # We group the duplicates together and select only one price (lowest id) for each group of duplicates.
  # We delete the selected duplicats and the remaining prices stay.
  # Since every variant has a maximum of two duplicates, we don't need to repeat this and the remaining prices are unique.
  def remove_duplicate_prices
    duplicate_half_of_prices = "SELECT min(id) id, variant_id, amount, currency FROM spree_prices GROUP BY variant_id, amount, currency HAVING COUNT(variant_id) > 1"
    File.write(DUPLICATES_FILE, select_all(duplicate_half_of_prices).to_json)
    duplicate_half_of_price_ids = "SELECT min(id) FROM spree_prices GROUP BY variant_id, amount, currency HAVING COUNT(variant_id) > 1"
    duplicate_count = select_value("SELECT count(*) FROM spree_prices WHERE id IN (#{duplicate_half_of_price_ids})")
    puts "Deleting #{duplicate_count} duplicate prices"
    delete("DELETE FROM spree_prices WHERE id IN (#{duplicate_half_of_price_ids})")
  end

  # We have conflicting prices for the same variant with the same currency as well.
  # Here we have to choose one over the other.
  # Since prices usually increase, the higher price is probably the up-to-date one.
  # Also if a shop displays a higher price, the item may not get sold,
  # but if the shop displays a lower price, it may loose money.
  # We figure that loosing money per sale is worse than customers to buying.
  # We compiled a list of products before so that the prices can be reviewed and adjusted.
  # SQL to get all affected products with both prices:
  #
  #     select e.name enterprise, p.name product, min(price.amount), max(price.amount), currency from spree_prices price join spree_variants v on price.variant_id = v.id join spree_products p on v.product_id=p.id join enterprises e on p.supplier_id=e.id group by e.name, p.name, variant_id, currency having count(variant_id) > 1;
  #
  # In this method we select both price ids for each conflicting price pair.
  # Just to be really clear, we use ActiveRecord to load these prices and compare them.
  # We then delete the lower price, leaving the higher price.
  # Equal prices should have been deleted in the previous step `remove_duplicate_prices`.
  def remove_conflicting_prices
    # find all conflicting price pairs
    price1_subquery = "SELECT MIN(id) FROM spree_prices GROUP BY variant_id, currency HAVING COUNT(variant_id) > 1"
    price2_subquery = "SELECT MAX(id) FROM spree_prices GROUP BY variant_id, currency HAVING COUNT(variant_id) > 1"
    price_pairs_query = "SELECT price1s.variant_id variant_id, price1s.id price1_id, price1s.amount price1_amount, price2s.id price2_id, price2s.amount price2_amount FROM "
    price_pairs_query += "(SELECT id, variant_id, amount FROM spree_prices WHERE id IN (#{price1_subquery})) price1s JOIN "
    price_pairs_query += "(SELECT id, variant_id, amount FROM spree_prices WHERE id IN (#{price2_subquery})) price2s "
    price_pairs_query += " ON price1s.variant_id = price2s.variant_id"
    price_pairs = select_all(price_pairs_query)
    old_prices = load_old_prices

    price1_ids_to_destroy = []
    price2_ids_to_destroy = []
    price2_changed_variant_ids = []
    mismatched_variant_ids = []

    # starting a recovery file
    File.open(CONFLICTS_FILE, 'w') do |log|
      # iterate one by one to simplify logic
      price_pairs.each do |pair|
        old_pair = old_prices[pair['variant_id']]
        new_price1 = Price.find pair['price1_id']
        new_price2 = Price.find pair['price2_id']
        old_price1_amount = old_pair.price1_amount
        old_price2_amount = old_pair.price2_amount

        if old_pair.price1_id != new_price1.id || old_pair.price2_id != new_price2.id
          puts "WARNING! Mismatched LOWER and HIGHER price ids between databases"
          mismatched_variant_ids << pair['variant_id']
        elsif old_price2_amount != new_price2.amount.to_f
          puts "WARNING! A price with a HIGHER id seems to have changed on the new server. According to our theory, this should not be possible."
          puts "DETAILS"
          puts "Variant ID: #{pair['variant_id']}, Old Price2: #{old_price2_amount}, New Price2: #{new_price2.amount.to_f}"
          price2_changed_variant_ids << new_price2.to_json
        elsif old_price1_amount != new_price1.amount.to_f
          # Destroy the price with the HIGHER id where the price with the LOWER id has changed between dbs
          log.write(new_price2.to_json)
          price2_ids_to_destroy << new_price2.id
        else
          # Destroy the price with the LOWER id where neither price has been changed between dbs
          log.write(new_price1.to_json)
          price1_ids_to_destroy << new_price1.id
        end
        log.write("\n")
      end

      if mismatched_variant_ids.any?
        puts "FOUND #{mismatched_variant_ids.count} variant IDs where a price LOWER and HIGHER price ids did not match"
        puts mismatched_variant_ids.join(',')
      end
      if price2_changed_variant_ids.any?
        puts "FOUND #{price2_changed_variant_ids.count} variant IDs where a price with a HIGHER id was changed:"
        puts price2_changed_variant_ids.join(',')
      end
      puts "Deleting #{price1_ids_to_destroy.count} prices with LOWER ids"
      delete("DELETE FROM spree_prices WHERE id IN (#{price1_ids_to_destroy.join(',')})")
      puts "Deleting #{price2_ids_to_destroy.count} prices with HIGHER ids"
      delete("DELETE FROM spree_prices WHERE id IN (#{price2_ids_to_destroy.join(',')})")
    end
  end

  def restore_duplicate_prices
    rows = JSON.parse File.read(DUPLICATES_FILE)
    rows.each do |price|
      Price.create({id: price['id'].to_i, variant_id: price['variant_id'].to_i, amount: price['amount'], currency: price['currency']}, without_protection: true)
    end
  end

  def restore_conflicting_prices
    File.open(CONFLICTS_FILE).each do |json|
      object = JSON.parse json
      price = object['price']
      Price.create({id: price['id'], variant_id: price['variant_id'], amount: price['amount'], currency: price['currency']}, without_protection: true)
    end
  end

  def load_old_prices
    CSV.foreach('old_prices.csv', headers: true).each_with_object({}) do |row, prices|
      prices[row['variant_id']] = OldPrice.new(row)
    end
  end
end
