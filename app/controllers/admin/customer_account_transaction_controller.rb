# frozen_string_literal: true

module Admin
  class CustomerAccountTransactionController < Admin::ResourceController
    MAX_AMOUNT = 100_000_000

    skip_before_action :load_resource, only: [:new, :create]
    before_action :authorize_customer_access, only: [:index, :new, :create]
    before_action :load_customer, only: [:index, :new, :create]

    helper_method :negative_amount_allowed?

    def index
      @available_credit = @collection.first&.balance || 0.00

      respond_with do |format|
        format.turbo_stream {
          render :index
        }
      end
    end

    def new
      @object = @customer.customer_account_transactions.new

      respond_with do |format|
        format.turbo_stream {
          render :new
        }
      end
    end

    def create
      @object = @customer.customer_account_transactions.new(permitted_resource_params)
      @object.created_by = spree_current_user
      @object.currency = CurrentConfig.get(:currency)
      validate_amount
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
      allowed = OpenFoodNetwork::Permissions.new(spree_current_user)
        .managed_enterprises.joins(:customers)
        .where(customers: { id: params[:customer_id].to_i })
        .exists?
      raise CanCan::AccessDenied unless allowed
    end

    def load_customer
      @customer = Customer.find(params[:customer_id])
    end

    # Only super admins may enter a negative amount, to deduct credit from a customer.
    # Hub managers are limited to adding credit.
    def validate_amount
      amount = @object.amount
      return add_amount_sign_error if amount.nil? || amount.zero?

      if amount.negative? && !negative_amount_allowed?
        add_amount_sign_error
      elsif amount.negative?
        validate_deduction(amount)
      elsif amount >= MAX_AMOUNT
        @object.errors.add(:amount, :less_than, count: MAX_AMOUNT)
      end
    end

    # A deduction must not leave the customer with a negative credit balance.
    def validate_deduction(amount)
      available_credit = @customer.credit_balance
      return if available_credit + amount >= 0

      @object.errors.add(:amount, :exceeds_available_credit,
                         available_credit: Spree::Money.new(available_credit).to_s)
    end

    def add_amount_sign_error
      if negative_amount_allowed?
        @object.errors.add(:amount, :other_than, count: 0)
      else
        @object.errors.add(:amount, :greater_than, count: 0)
      end
    end

    def negative_amount_allowed?
      spree_current_user.admin?
    end

    def permitted_resource_params
      params.require(:customer_account_transaction).permit(:amount, :description)
    end
  end
end
