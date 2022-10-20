# frozen_string_literal: true

class EnterpriseEditReflex < ApplicationReflex
  def toggle_guest_order_row(require_login, allow_order_changes, allow_guest_orders)
    @enterprise = Enterprise.find(3)
    @enterprise.require_login = require_login
    @enterprise.allow_order_changes = allow_order_changes
    @enterprise.allow_guest_orders = allow_guest_orders
    morph '#guest_orders_row',
          render(partial: 'admin/enterprises/form/guest_orders_row',
                 locals: { enterprise: @enterprise })
  end
end
