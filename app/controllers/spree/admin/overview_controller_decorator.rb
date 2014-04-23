module Spree
  module Admin
    class OverviewController < Spree::Admin::BaseController
      def index
        if current_spree_user.admin? || current_spree_user.enterprises.any?{ |e| e.is_distributor? }
          redirect_to admin_orders_path
        elsif current_spree_user.enterprises.any?{ |e| e.is_primary_producer? }
          redirect_to bulk_edit_admin_products_path
        end
      end
    end
  end
end