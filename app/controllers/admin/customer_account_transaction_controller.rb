# frozen_string_literal: true

module Admin
  class CustomerAccountTransactionController < Admin::ResourceController
    before_action :load_customer, only: [:index, :new, :create]
    before_action :authorize_customer_access, only: [:index, :new, :create]
    skip_before_action :load_resource, only: [:new, :create]

    def index
      @available_credit = @collection.first&.balance || 0.00
    end

    def new
      @object = @customer.customer_account_transactions.new
    end

    def create
      @object = @customer.customer_account_transactions.new(permitted_resource_params)
      @object.created_by = spree_current_user
      @object.currency = CurrentConfig.get(:currency)
      @object.errors.add(:amount, :greater_than, count: 0) if non_positive_amount?
      @object.errors.add(:amount, :less_than, count: 100_000_000) if amount_too_large?
      @object.errors.add(:description, :blank) if @object.description.blank?

      if @object.errors.empty? && @object.save
        @available_credit = @object.balance
        @collection = collection

        respond_with do |format|
          format.turbo_stream {
            render :index
          }
        end
      else
        respond_with do |format|
          format.turbo_stream {
            render :new
          }
        end
      end
    end

    # We are using an old version of CanCanCan so I could not get `accessible_by` to work properly,
    # so we are doing our own authorization before calling 'accessible_by'
    def collection
      CustomerAccountTransaction.accessible_by(current_ability, action)
        .where(customer_id: params[:customer_id]).order(id: :desc)
    end

    private

    def authorize_customer_access
      authorize! :create_customer_account_transaction, @customer
    end

    def load_customer
      @customer = Customer.find(params[:customer_id])
    end

    def non_positive_amount?
      @object.amount.nil? || @object.amount <= 0
    end

    def amount_too_large?
      @object.amount.present? && @object.amount >= 100_000_000
    end

    def permitted_resource_params
      params.require(:customer_account_transaction).permit(:amount, :description)
    end
  end
end
