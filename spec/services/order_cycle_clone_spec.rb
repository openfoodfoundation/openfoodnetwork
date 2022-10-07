# frozen_string_literal: true

require 'spec_helper'

describe OrderCycleForm do
  describe "#create" do
    it "clones the order cycle" do
      coordinator = create(:enterprise);
      oc = create(:simple_order_cycle,
                  coordinator_fees: [create(:enterprise_fee, enterprise: coordinator)],
                  preferred_product_selection_from_coordinator_inventory_only: true,
                  automatic_notifications: true, processed_at: Time.zone.now, mails_sent: true)
      schedule = create(:schedule, order_cycles: [oc])
      ex1 = create(:exchange, order_cycle: oc)
      ex2 = create(:exchange, order_cycle: oc)

      occ = OrderCycleClone.new(oc).create
      expect(occ.name).to eq("COPY OF #{oc.name}")
      expect(occ.orders_open_at).to be_nil
      expect(occ.orders_close_at).to be_nil
      expect(occ.coordinator).not_to be_nil
      expect(occ.preferred_product_selection_from_coordinator_inventory_only).to be true
      expect(occ.automatic_notifications).to eq(oc.automatic_notifications)
      expect(occ.processed_at).to eq(nil)
      expect(occ.mails_sent).to eq(nil)
      expect(occ.coordinator).to eq(oc.coordinator)

      expect(occ.coordinator_fee_ids).not_to be_empty
      expect(occ.coordinator_fee_ids).to eq(oc.coordinator_fee_ids)
      expect(occ.preferred_product_selection_from_coordinator_inventory_only).to eq(
        oc.preferred_product_selection_from_coordinator_inventory_only
      )
      expect(occ.schedule_ids).not_to be_empty
      expect(occ.schedule_ids).to eq(oc.schedule_ids)

      # Check that the exchanges have been cloned.
      original_exchange_attributes = oc.exchanges.map { |ex| core_exchange_attributes(ex) }
      cloned_exchange_attributes = occ.exchanges.map { |ex| core_exchange_attributes(ex) }

      expect(cloned_exchange_attributes).to match_array original_exchange_attributes
    end

    context "when it has selected payment methods which can longer be applied validly
             e.g. payment method is backoffice only" do
      it "only attaches the valid ones to the clone" do
        distributor = create(:distributor_enterprise)
        distributor_payment_method_i = create(
          :payment_method,
          distributors: [distributor]
        ).distributor_payment_methods.first
        distributor_payment_method_ii = create(
          :payment_method,
          distributors: [distributor],
          display_on: "back_end"
        ).distributor_payment_methods.first
        order_cycle = create(:distributor_order_cycle, distributors: [distributor])
        order_cycle.selected_distributor_payment_methods = [
          distributor_payment_method_i,
          distributor_payment_method_ii
        ]

        cloned_order_cycle = order_cycle.clone!

        expect(cloned_order_cycle.distributor_payment_methods).to eq [distributor_payment_method_i]
      end
    end

    context "when it has selected shipping methods which can longer be applied validly
             e.g. shipping method is backoffice only" do
      it "only attaches the valid ones to the clone" do
        distributor = create(:distributor_enterprise)
        distributor_shipping_method_i = create(
          :shipping_method,
          distributors: [distributor]
        ).distributor_shipping_methods.first
        distributor_shipping_method_ii = create(
          :shipping_method,
          distributors: [distributor],
          display_on: Spree::ShippingMethod::DISPLAY_ON_OPTIONS[:back_end]
        ).distributor_shipping_methods.first
        order_cycle = create(:distributor_order_cycle, distributors: [distributor])
        order_cycle.selected_distributor_shipping_methods = [
          distributor_shipping_method_i,
          distributor_shipping_method_ii
        ]

        cloned_order_cycle = order_cycle.clone!

        expect(cloned_order_cycle.distributor_shipping_methods).to eq [
          distributor_shipping_method_i
        ]
      end
    end
  end

  private

  def core_exchange_attributes(exchange)
    exterior_attribute_keys = %w(id order_cycle_id created_at updated_at)
    exchange.attributes.
      reject { |k| exterior_attribute_keys.include? k }.
      merge(
        'variant_ids' => exchange.variant_ids.sort,
        'enterprise_fee_ids' => exchange.enterprise_fee_ids.sort
      )
  end
end
