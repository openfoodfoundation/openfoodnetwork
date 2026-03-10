# frozen_string_literal: true

module Admin
  class CustomerAccountTransactionController < Admin::ResourceController
    def index
      @available_credit = @collection.first&.balance || 0.00

      respond_with do |format|
        format.turbo_stream {
          render :index
        }
      end
    end

    # We are using an old version of CanCanCan so I could not get `accessible_by` to work properly,
    # so we are doing our own authorization before calling 'accessible_by'
    def collection
      allowed_customers = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_enterprises.joins(:customers).select("customers.id").map(&:id)
      raise CanCan::AccessDenied unless allowed_customers.include?(params[:customer_id].to_i)

      CustomerAccountTransaction.accessible_by(current_ability, action)
        .where(customer_id: params[:customer_id]).order(id: :desc)
    end
  end
end
