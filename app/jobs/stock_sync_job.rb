# frozen_string_literal: true

class StockSyncJob < ApplicationJob
  # No retry but stay as failed job:
  sidekiq_options retry: 0

  # We synchronise stock of stock-controlled variants linked to a remote
  # product. These variants are rare though and we check first before we
  # enqueue a new job. That should save some time loading the order with
  # all the stock data to make this decision.
  def self.sync_linked_catalogs(order)
    user = order.distributor.owner
    catalog_ids(order).each do |catalog_id|
      perform_later(user, catalog_id)
    end
  rescue StandardError => e
    # Errors here shouldn't affect the shopping. So let's report them
    # separately:
    Bugsnag.notify(e) do |payload|
      payload.add_metadata(:order, :order, order)
    end
  end

  def self.sync_linked_catalogs_now(order)
    user = order.distributor.owner
    catalog_ids(order).each do |catalog_id|
      perform_now(user, catalog_id)
    end
  rescue StandardError => e
    # Errors here shouldn't affect the shopping. So let's report them
    # separately:
    Bugsnag.notify(e) do |payload|
      payload.add_metadata(:order, :order, order)
    end
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
    products = load_products(user, catalog_id)
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

  def load_products(user, catalog_id)
    json_catalog = DfcRequest.new(user).call(catalog_id)
    graph = DfcIo.import(json_catalog)

    graph.select do |subject|
      subject.is_a? DataFoodConsortium::Connector::SuppliedProduct
    end
  end

  def linked_variants(enterprises, product_ids)
    Spree::Variant.where(supplier: enterprises)
      .includes(:semantic_links).references(:semantic_links)
      .where(semantic_links: { semantic_id: product_ids })
  end
end
