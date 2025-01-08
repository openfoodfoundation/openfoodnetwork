# frozen_string_literal: true

class StockSyncJob < ApplicationJob
  # No retry but stay as failed job:
  sidekiq_options retry: 0

  # We synchronise stock of stock-controlled variants linked to a remote
  # product. These variants are rare though and we check first before we
  # enqueue a new job. That should save some time loading the order with
  # all the stock data to make this decision.
  def self.sync_linked_catalogs_later(order)
    sync_catalogs_by_perform_method(order, :perform_later)
  end

  def self.sync_linked_catalogs_now(order)
    sync_catalogs_by_perform_method(order, :perform_now)
  end

  def self.catalog_ids(order)
    stock_controlled_variants = order.variants.reject(&:on_demand)
    links = SemanticLink.where(subject: stock_controlled_variants)
    semantic_ids = links.pluck(:semantic_id)
    semantic_ids.map do |product_id|
      FdcUrlBuilder.new(product_id).catalog_url
    end.uniq
  end

  def perform(user, catalog_id)
    catalog = DfcCatalog.load(user, catalog_id)
    catalog.apply_wholesale_values!

    products = catalog.products
    products_by_id = products.index_by(&:semanticId)
    product_ids = products_by_id.keys
    variants = linked_variants(user.enterprises, product_ids)

    # Avoid race condition between checkout and stock sync.
    Spree::Variant.transaction do
      variants.order(:id).lock.each do |variant|
        next if variant.on_demand

        product = products_by_id[variant.semantic_links[0].semantic_id]
        catalog_item = product&.catalogItems&.first
        CatalogItemBuilder.apply_stock(catalog_item, variant)
        variant.stock_items[0].save!
      end
    end
  end

  def linked_variants(enterprises, product_ids)
    Spree::Variant.where(supplier: enterprises)
      .includes(:semantic_links).references(:semantic_links)
      .where(semantic_links: { semantic_id: product_ids })
  end

  def self.sync_catalogs_by_perform_method(order, perform_method)
    distributor = order.distributor
    return unless distributor

    user = distributor.owner
    catalog_ids(order).each do |catalog_id|
      public_send(perform_method, user, catalog_id)
    end
  rescue StandardError => e
    # Errors here shouldn't affect the shopping. So let's report them
    # separately:
    Alert.raise_with_record(e, order)
  end
end
