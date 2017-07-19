module Spree
  class CreditCardsController < BaseController
    before_filter :set_credit_card, only: [:destroy]
    before_filter :destroy_at_stripe, only: [:destroy]

    def new_from_token
      # A new Customer is created for every credit card (same as via ActiveMerchant)
      # Note that default_source is the card represented by the token

      @customer = create_customer(params[:token])
      @credit_card = build_card_from(stored_card_attributes)
      if @credit_card.save
        render json: @credit_card, serializer: ::Api::CreditCardSerializer, status: :ok
      else
        message = t(:card_could_not_be_saved)
        render json: { flash: { error: I18n.t(:spree_gateway_error_flash_for_checkout, error: message) } }, status: 400
      end
    rescue Stripe::CardError => e
      return render json: { flash: { error: I18n.t(:spree_gateway_error_flash_for_checkout, error: e.message) } }, status: 400
    end

    def destroy
      if @credit_card.destroy
        flash[:success] = I18n.t(:card_has_been_removed, number: "x-#{@credit_card.last_digits}")
      else
        flash[:error] = I18n.t(:card_could_not_be_removed)
      end
      redirect_to "/account#/cards"
    end

    # Currently can only destroy the whole customer object
    def destroy_at_stripe
      stripe_customer = Stripe::Customer.retrieve(@credit_card.gateway_customer_profile_id)
      stripe_customer.delete if stripe_customer
    end

    private

    def create_customer(token)
      Stripe::Customer.create(email: spree_current_user.email, source: token)
    end

    def stored_card_attributes
      return {} unless @customer.try(:default_source)
      {
        month: params[:exp_month],
        year: params[:exp_year],
        last_digits: params[:last4],
        gateway_payment_profile_id: @customer.default_source,
        gateway_customer_profile_id: @customer.id,
        cc_type: params[:cc_type]
      }
    end

    def build_card_from(attrs)
      card = Spree::CreditCard.new(attrs)
      # Can't mass assign user:
      card.user_id = spree_current_user.id
      card
    end

    def set_credit_card
      @credit_card = Spree::CreditCard.find(params[:id])
    end
  end
end
