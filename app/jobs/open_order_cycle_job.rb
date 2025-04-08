# frozen_string_literal: true

# Run any pre-conditions and mark order cycle as open.
#
# Currently, an order cycle is considered open in the shopfront when orders_open_at >= now.
# But now there are some pre-conditions for opening an order cycle, so we would like to change that.
# Instead, the presence of opened_at (and absence of processed_at) should indicate it is open.
class OpenOrderCycleJob < ApplicationJob
  sidekiq_options retry_for: 10.minutes

  def perform(order_cycle_id)
    ActiveRecord::Base.transaction do
      # Fetch order cycle if it's still unopened, and lock DB row until finished
      order_cycle = OrderCycle.lock.find_by!(id: order_cycle_id, opened_at: nil)

      sync_remote_variants(order_cycle)

      # Mark as opened
      opened_at = Time.zone.now
      order_cycle.update_columns(opened_at:)

      # And notify any subscribers
      OrderCycles::WebhookService.create_webhook_job(order_cycle, 'order_cycle.opened', opened_at)
    end
  end

  private

  def sync_remote_variants(order_cycle)
    # Sync any remote variants for each supplier
    order_cycle.suppliers.each do |supplier|
      links = variant_links_for(order_cycle, supplier)
      next if links.empty?

      # Find authorised user to access remote products
      dfc_user = supplier.owner # we assume the owner's account is the one used to import from dfc.

      import_variants(links, dfc_user)
    end
  end

  # Fetch all remote variants for this supplier in the order cycle
  def variant_links_for(order_cycle, supplier)
    variants = order_cycle.exchanges.incoming.from_enterprise(supplier)
      .joins(:exchange_variants).select('exchange_variants.variant_id')
    SemanticLink.where(subject_id: variants)
  end

  def import_variants(links, dfc_user)
    # Find any catalogues associated with the variants
    catalogs = links.group_by do |link|
      FdcUrlBuilder.new(link.semantic_id).catalog_url
    end

    # Import selected variants from each catalog
    catalogs.each do |catalog_url, catalog_links|
      catalog = DfcCatalog.load(dfc_user, catalog_url)
      catalog.apply_wholesale_values!

      catalog_links.each do |link|
        catalog_item = catalog.item(link.semantic_id)

        if catalog_item
          SuppliedProductImporter.update_product(catalog_item, link.subject)
        else
          DfcCatalogImporter.reset_variant(link.subject)
        end
      end
    end
  end
end
