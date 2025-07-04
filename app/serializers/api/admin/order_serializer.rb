# frozen_string_literal: true

module Api
  module Admin
    class OrderSerializer < ActiveModel::Serializer
      include AddressDisplay

      attributes :id, :number, :user_id, :full_name, :full_name_for_sorting, :email, :phone,
                 :completed_at, :completed_at_utc_iso8601, :display_total,
                 :edit_path, :state, :payment_state, :shipment_state,
                 :payments_path, :ready_to_ship, :ready_to_capture, :created_at,
                 :distributor_name, :special_instructions, :display_outstanding_balance,
                 :item_total, :adjustment_total, :payment_total, :total, :item_count

      has_one :distributor, serializer: Api::Admin::IdSerializer
      has_one :order_cycle, serializer: Api::Admin::IdSerializer

      def full_name_for_sorting
        value = [last_name, first_name].compact_blank.join(", ")
        display_value_for_producer(object, value)
      end

      def full_name
        value = object.billing_address.nil? ? "" : ( object.billing_address.full_name || "" )
        display_value_for_producer(object, value)
      end

      def first_name
        object.billing_address&.first_name || ""
      end

      def last_name
        object.billing_address&.last_name || ""
      end

      def distributor_name
        object.distributor&.name
      end

      def display_outstanding_balance
        return "" if object.outstanding_balance.zero?

        object.display_outstanding_balance.to_s
      end

      def edit_path
        return '' unless object.id

        spree_routes_helper.edit_admin_order_path(object)
      end

      def payments_path
        return '' unless object.payment_state

        spree_routes_helper.admin_order_payments_path(object)
      end

      # This methods requires to eager load the payment association (with its required WHERE
      # constraints) so as not to cause and N+1.
      def ready_to_capture
        pending_payments = object.pending_payments.reject(&:requires_authorization?)
        object.payment_required? && pending_payments.any?
      end

      def ready_to_ship
        object.ready_to_ship?
      end

      def display_total
        object.display_total.to_html
      end

      def email
        display_value_for_producer(object, object.email || "")
      end

      def phone
        value = object.billing_address.nil? ? "a" : ( object.billing_address.phone || "" )
        display_value_for_producer(object, value)
      end

      def created_at
        object.created_at.blank? ? "" : I18n.l(object.created_at, format: '%B %d, %Y')
      end

      def completed_at
        object.completed_at.blank? ? "" : I18n.l(object.completed_at, format: '%B %d, %Y')
      end

      def item_count
        object.line_items.count
      end

      def completed_at_utc_iso8601
        object.completed_at.blank? ? "" : object.completed_at.utc.iso8601
      end

      private

      def spree_routes_helper
        Spree::Core::Engine.routes.url_helpers
      end

      def display_value_for_producer(order, value)
        @ability ||= Spree::Ability.new(options[:current_user])
        filter_by_supplier = @ability.can?(:edit_as_producer_only, order)
        return value unless filter_by_supplier

        if order.distributor&.show_customer_names_to_suppliers
          value
        else
          I18n.t("admin.reports.hidden_field")
        end
      end
    end
  end
end
