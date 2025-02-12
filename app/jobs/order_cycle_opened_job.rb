# frozen_string_literal: true

# Trigger jobs for any order cycles that recently opened
class OrderCycleOpenedJob < ApplicationJob
  def perform
    ActiveRecord::Base.transaction do
      recently_opened_order_cycles.find_each do |order_cycle|
        # Process the order cycle. this might take a while, so this should be shifted to a separate job to allow concurrent processing.        

        # Sync any remote products
        updated_products = order_cycle.products.joins(:semantic_links).find_each.map do |product|
          DfcImporter.import(product) # request DFC product from semantic_id and import it. may take some time
        end
        # actually, that might not be possible. 
        # Instead we might use FdcUrlBuilder and load the whole shop catalogue (which is probably more efficient anyway)

        # then notify shop owners. and/or order cycle co-ordinator.
        OcSyncedMailer.new(to: contacts, order_cycle, updated_products).deliver_later

        # and notify anyone else
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
