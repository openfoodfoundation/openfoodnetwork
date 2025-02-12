# frozen_string_literal: true

# Trigger jobs for any order cycles that recently opened
class OrderCycleOpenedJob < ApplicationJob
  def perform
    ActiveRecord::Base.transaction do
      recently_opened_order_cycles.find_each do |order_cycle|
        # Process the order cycle. this might take a while, so this should be shifted to a separate job to allow concurrent processing.        

        order_cycle.suppliers.each do |supplier|
          # Find authorised user to access remote products
          dfc_user = supplier.owner # we assume the owner's account is the one used to import from dfc.

          # Fetch all variants for this supplier in the order cycle
          variants = order_cycle.exchanges.incoming.from_enterprise(supplier).joins(:exchange_variants).select('exchange_variants.variant_id')
          links = SemanticLink.where(subject_id: variants)

          # Find any catalogues associated with the variants
          catalogs = links.group_by do |link|
            FdcUrlBuilder.new(link.semantic_id).catalog_url
          end

          # Import selected variants from each catalog
          catalogs.each do |catalog_url, catalog_links|
            catalog_json = DfcRequest.new(dfc_user).call(catalog_url)
            graph = DfcIo.import(catalog_json)
            catalog = DfcCatalog.new(graph)
            catalog.apply_wholesale_values!

            catalog_links.each do |link|
              catalog_item = catalog.item(link.semantic_id)

              SuppliedProductImporter.update_product(catalog_item, link.subject) if catalog_item
            end
          end
        end

        # And notify any subscribers
        OrderCycles::WebhookService.create_webhook_job(order_cycle, 'order_cycle.opened')
      end
      mark_as_opened(recently_opened_order_cycles)
    end
  end

  private

  def recently_opened_order_cycles
    @recently_opened_order_cycles ||= OrderCycle
      .where(opened_at: nil)
      .where(orders_open_at: 1.hour.ago..Time.zone.now)
      .lock.order(:id)
  end

  def mark_as_opened(order_cycles)
    now = Time.zone.now
    order_cycles.update_all(opened_at: now, updated_at: now)
  end
end
