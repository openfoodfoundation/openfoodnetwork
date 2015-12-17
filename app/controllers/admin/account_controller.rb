class Admin::AccountController < Spree::Admin::BaseController

  def show
    @invoices = spree_current_user.account_invoices
  end
end
