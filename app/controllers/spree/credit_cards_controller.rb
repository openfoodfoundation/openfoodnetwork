# frozen_string_literal: true

require 'stripe/credit_card_remover'

module Spree
  class CreditCardsController < BaseController
    def new_from_token
      # A new Customer is created for every credit card (same as via ActiveMerchant)
      # Note that default_source is the card represented by the token

      @customer = create_customer(params[:token])
      @credit_card = build_card_from(stored_card_attributes)
      if @credit_card.save
        render json: @credit_card, serializer: ::Api::CreditCardSerializer, status: :ok
      else
        message = t(:card_could_not_be_saved)
        render json: { flash: { error: I18n.t(:spree_gateway_error_flash_for_checkout,
                                              error: message) } },
               status: :bad_request
      end
    rescue Stripe::CardError => e
      render json: { flash: { error: I18n.t(:spree_gateway_error_flash_for_checkout,
                                            error: e.message) } },
             status: :bad_request
    end

    def update
      @credit_card = Spree::CreditCard.find_by(id: params[:id])
      return update_failed unless @credit_card

      authorize! :update, @credit_card

      if @credit_card.update(credit_card_params)
        remove_shop_authorizations if credit_card_params["is_default"]
        render json: @credit_card, serializer: ::Api::CreditCardSerializer, status: :ok
      else
        update_failed
      end
    rescue ArgumentError
      update_failed
    end

    def destroy
      @credit_card = Spree::CreditCard.find_by(id: params[:id])
      if @credit_card
        authorize! :destroy, @credit_card
        Stripe::CreditCardRemover.new(@credit_card).call
      end

      # Using try because we may not have a card here
      if @credit_card.try(:destroy)
        if @credit_card.is_default
          remove_shop_authorizations
          mark_as_default_next_credit_card if credit_cards_with_payment_profile.count > 0
        end
        flash[:success] = I18n.t(:card_has_been_removed, number: "x-#{@credit_card.last_digits}")
      else
        flash[:error] = I18n.t(:card_could_not_be_removed)
      end

      head :ok
    rescue Stripe::CardError
      flash[:error] = I18n.t(:card_could_not_be_removed)
      head :unprocessable_entity
    end

    private

    def remove_shop_authorizations
      @credit_card.user.customers.update_all(allow_charges: false)
    end

    def mark_as_default_next_credit_card
      credit_cards_with_payment_profile.first.update(is_default: true)
    end

    def credit_cards_with_payment_profile
      spree_current_user.credit_cards.with_payment_profile
    end

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

    def update_failed
      render json: { flash: { error: t(:card_could_not_be_updated) } }, status: :bad_request
    end

    def credit_card_params
      params.require(:credit_card).permit(:is_default, :year, :month)
    end
  end
end
