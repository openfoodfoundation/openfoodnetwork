# frozen_string_literal: true

module Spree
  module Admin
    module OrdersHelper
      def event_links(order)
        links = []
        links << cancel_event_link(order) if order.can_cancel?
        links << resume_event_link(order) if order.can_resume?
        links.join('&nbsp;').html_safe # rubocop:disable Rails/OutputSafety
      end

      def generate_invoice_button(order)
        if order.distributor.can_invoice?
          button_link_to t(:create_or_update_invoice), generate_admin_order_invoices_path(order),
                         data: { method: 'post' }, icon: 'icon-plus'
        else
          button_link_to t(:create_or_update_invoice), "#", data: {
            confirm: t(:must_have_valid_business_number, enterprise_name: order.distributor.name)
          }, icon: 'icon-plus'
        end
      end

      def line_item_shipment_price(line_item, quantity)
        Spree::Money.new(line_item.price * quantity, currency: line_item.currency)
      end

      def order_links(order)
        links = []
        links << edit_order_link(order) unless action_name == "edit"
        links.concat(complete_order_links(order)) if order.complete? || order.resumed?
        links << ship_order_link if order.ready_to_ship?
        links << cancel_order_link(order) if order.can_cancel?
        links
      end

      def order_shipment_ready?(order)
        order.ready_to_ship?
      end

      private

      def complete_order_links(order)
        [resend_confirmation_link(order)] + invoice_links(order)
      end

      def invoice_links(order)
        return [] unless Spree::Config[:enable_invoices?]

        [send_invoice_link(order), print_invoice_link(order)]
      end

      def send_invoice_link(order)
        if order.distributor.can_invoice?
          send_invoice_link_with_url(order)
        else
          send_invoice_link_without_url(order)
        end
      end

      def print_invoice_link(order)
        if order.distributor.can_invoice?
          print_invoice_link_with_url(order)
        else
          notify_about_required_enterprise_number(order)
        end
      end

      def edit_order_link(order)
        { name: t(:edit_order),
          url: spree.edit_admin_order_path(order),
          icon: 'icon-edit' }
      end

      def resend_confirmation_link(order)
        { name: t(:resend_confirmation),
          url: spree.resend_admin_order_path(order),
          icon: 'icon-email',
          confirm: t(:confirm_resend_order_confirmation) }
      end

      def send_invoice_link_with_url(order)
        { name: t(:send_invoice),
          url: invoice_admin_order_path(order),
          icon: 'icon-email',
          confirm: t(:confirm_send_invoice) }
      end

      def send_invoice_link_without_url(order)
        { name: t(:send_invoice),
          url: "#",
          icon: 'icon-email',
          confirm: t(:must_have_valid_business_number, enterprise_name: order.distributor.name) }
      end

      def print_invoice_link_with_url(order)
        { name: t(:print_invoice),
          url: spree.print_admin_order_path(order),
          icon: 'icon-print',
          target: "_blank" }
      end

      def notify_about_required_enterprise_number(order)
        { name: t(:print_invoice),
          url: "#",
          icon: 'icon-print',
          confirm: t(:must_have_valid_business_number, enterprise_name: order.distributor.name) }
      end

      def ship_order_link
        { name: t(:ship_order),
          url: '#',
          icon: 'icon-truck' }
      end

      def cancel_order_link(order)
        { name: t(:cancel_order),
          url: spree.fire_admin_order_path(order.number, e: 'cancel'),
          icon: 'icon-trash' }
      end

      def cancel_event_link(order)
        event_label = I18n.t("cancel", scope: "actions")
        button_link_to(event_label,
                       fire_admin_order_url(order, e: "cancel"),
                       method: :put, icon: "icon-cancel", form_id: "cancel_order_form")
      end

      def resume_event_link(order)
        event_label = I18n.t("resume", scope: "actions")
        confirm_message = I18n.t("admin.orders.edit.order_sure_want_to", event: event_label)
        button_link_to(event_label,
                       fire_admin_order_url(order, e: "resume"),
                       method: :put, icon: "icon-resume",
                       data: { confirm: confirm_message })
      end

      def quantity_field_tag(manifest_item)
        html_options = { min: 0, class: "line_item_quantity", size: 5 }
        unless manifest_item.variant.on_demand
          html_options.merge!(max: manifest_item.variant.on_hand + manifest_item.quantity)
        end
        number_field_tag :quantity, manifest_item.quantity, html_options
      end

      def prepare_shipment_manifest(shipment)
        manifest = shipment.manifest

        if filter_by_supplier?(shipment.order)
          supplier_ids = spree_current_user.enterprises.ids
          manifest.select! { |mi| supplier_ids.include?(mi.variant.supplier_id) }
        end

        manifest
      end

      def filter_by_supplier?(order)
        can? :edit_as_producer_only, order
      end

      def display_value_for_producer(order, value)
        return value unless filter_by_supplier?(order)

        if order.distributor&.show_customer_names_to_suppliers
          value
        else
          t("admin.reports.hidden_field")
        end
      end
    end
  end
end
