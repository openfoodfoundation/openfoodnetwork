module Spree
  module Admin
    module OrdersHelper
      def order_links(order)
        links = []
        links << { name: t(:view_order), url: admin_order_path(order), icon: 'icon-eye-open' } unless action_name == "show"
        links << { name: t(:edit_order), url: edit_admin_order_path(order), icon: 'icon-edit' } unless action_name == "edit"
        if @order.complete?
          links << { name: t(:resend_confirmation), url: resend_admin_order_path(order), icon: 'icon-email', method: 'post', confirm: t(:confirm_resend_order_confirmation) }
          if @order.distributor.can_invoice?
            links << { name: t(:send_invoice), url: invoice_admin_order_path(order), icon: 'icon-email', confirm: t(:confirm_send_invoice) }
          else
            links << { name: t(:send_invoice), url: "#", icon: 'icon-email', confirm: t(:must_have_valid_business_number, enterprise_name: order.distributor.name) }
          end
          links << { name: t(:print_invoice), url: print_admin_order_path(order), icon: 'icon-print', target: "_blank" }
          if Spree::Config.enable_receipt_printing?
            links << { name: t(:print_ticket), url: print_ticket_admin_order_path(order), icon: 'icon-print', target: "_blank" }
            links << { name: t(:select_ticket_printer), url: "#{print_ticket_admin_order_path(order)}#select-printer", icon: 'icon-print', target: "_blank" }
          end
        end
        if @order.ready_to_ship?
          links << { name: t(:ship_order), url: fire_admin_order_path(@order, :e => 'ship'), method: 'put', icon: 'icon-truck', confirm: t(:are_you_sure) }
        end
        links << { name: t(:cancel_order), url: fire_admin_order_path(@order.number, { :e => 'cancel' }), icon: 'icon-trash', confirm: t(:are_you_sure) } if order.can_cancel?
        links
      end
    end
  end
end
