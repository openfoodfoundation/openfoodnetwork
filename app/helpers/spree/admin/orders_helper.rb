# frozen_string_literal: true

module Spree
  module Admin
    module OrdersHelper
      def event_links
        links = []
        links << event_link("cancel") if @order.can_cancel?
        links << event_link("resume") if @order.can_resume?
        links.join('&nbsp;').html_safe
      end

      def line_item_shipment_price(line_item, quantity)
        Spree::Money.new(line_item.price * quantity, currency: line_item.currency)
      end

      def order_links(order)
        @order ||= order
        links = []
        links << edit_order_link unless action_name == "edit"
        links.concat(complete_order_links) if @order.complete?
        links << ship_order_link if @order.ready_to_ship?
        links << cancel_order_link if @order.can_cancel?
        links
      end

      private

      def complete_order_links
        [resend_confirmation_link] + invoice_links + ticket_links
      end

      def invoice_links
        return [] unless Spree::Config[:enable_invoices?]

        [send_invoice_link, print_invoice_link]
      end

      def send_invoice_link
        if @order.distributor.can_invoice?
          send_invoice_link_with_url
        else
          send_invoice_link_without_url
        end
      end

      def ticket_links
        return [] unless Spree::Config[:enable_receipt_printing?]

        [print_ticket_link, select_ticket_printer_link]
      end

      def edit_order_link
        { name: t(:edit_order),
          url: spree.edit_admin_order_path(@order),
          icon: 'icon-edit' }
      end

      def resend_confirmation_link
        { name: t(:resend_confirmation),
          url: spree.resend_admin_order_path(@order),
          icon: 'icon-email',
          method: 'post',
          confirm: t(:confirm_resend_order_confirmation) }
      end

      def send_invoice_link_with_url
        { name: t(:send_invoice),
          url: invoice_admin_order_path(@order),
          icon: 'icon-email',
          confirm: t(:confirm_send_invoice) }
      end

      def send_invoice_link_without_url
        { name: t(:send_invoice),
          url: "#",
          icon: 'icon-email',
          confirm: t(:must_have_valid_business_number, enterprise_name: @order.distributor.name) }
      end

      def print_invoice_link
        { name: t(:print_invoice),
          url: spree.print_admin_order_path(@order),
          icon: 'icon-print',
          target: "_blank" }
      end

      def print_ticket_link
        { name: t(:print_ticket),
          url: print_ticket_admin_order_path(@order),
          icon: 'icon-print',
          target: "_blank" }
      end

      def select_ticket_printer_link
        { name: t(:select_ticket_printer),
          url: "#{print_ticket_admin_order_path(@order)}#select-printer",
          icon: 'icon-print',
          target: "_blank" }
      end

      def ship_order_link
        { name: t(:ship_order),
          url: spree.fire_admin_order_path(@order, e: 'ship'),
          method: 'put',
          icon: 'icon-truck',
          confirm: t(:are_you_sure) }
      end

      def cancel_order_link
        { name: t(:cancel_order),
          url: spree.fire_admin_order_path(@order.number, e: 'cancel'),
          icon: 'icon-trash',
          confirm: t(:are_you_sure) }
      end

      def event_link(event)
        event_label = I18n.t(event, scope: "actions")
        confirm_message = I18n.t("admin.orders.edit.order_sure_want_to", event: event_label)
        button_link_to(event_label,
                       fire_admin_order_url(@order, e: event),
                       method: :put, icon: "icon-#{event}",
                       data: { confirm: confirm_message })
      end

      def quantity_field_tag(manifest_item)
        html_options = { min: 0, class: "line_item_quantity", size: 5 }
        unless manifest_item.variant.on_demand
          html_options.merge!(max: manifest_item.variant.on_hand + manifest_item.quantity)
        end
        number_field_tag :quantity, manifest_item.quantity, html_options
      end
    end
  end
end
