module Spree
  module Admin
    module OrdersHelper
      def order_links(order)
        @order ||= order
        links = []
        links << edit_order_link unless action_name == "edit"
        if @order.complete?
          links << resend_confirmation_link
          if @order.distributor.can_invoice?
            links << send_invoice_link_with_url
          else
            links << send_invoice_link_without_url
          end
          links << print_invoice_link
          if Spree::Config.enable_receipt_printing?
            links << print_ticket_link
            links << select_ticket_printer_link
          end
        end
        if @order.ready_to_ship?
          links << ship_order_link
        end
        links << cancel_order_link if @order.can_cancel?
        links
      end

      private

      def edit_order_link
        { name: t(:edit_order),
          url: edit_admin_order_path(@order),
          icon: 'icon-edit' }
      end

      def resend_confirmation_link
        { name: t(:resend_confirmation),
          url: resend_admin_order_path(@order),
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
          url: print_admin_order_path(@order),
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
          url: fire_admin_order_path(@order, e: 'ship'),
          method: 'put',
          icon: 'icon-truck',
          confirm: t(:are_you_sure) }
      end

      def cancel_order_link
        { name: t(:cancel_order),
          url: fire_admin_order_path(@order.number, e: 'cancel'),
          icon: 'icon-trash',
          confirm: t(:are_you_sure) }
      end
    end
  end
end
