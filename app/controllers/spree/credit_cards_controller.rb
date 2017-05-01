module Spree
  class CreditCardsController < BaseController

    before_filter :set_credit_card, only: [:destroy]
    before_filter :destroy_at_stripe, only: [:destroy]

    def new_from_token
      set_user
      # At the moment a new Customer is created for every credit card (even via ActiveMerchant),
      # so doing the same here (for now).
      if @customer = create_customer(params[:token])
      # Since it's a new customer, the default_source is the card that our original token represented
        credit_card_params = format_credit_card_params(params)
                                .merge({gateway_payment_profile_id: @customer.default_source,
                                        gateway_customer_profile_id: @customer.id,
                                        cc_type: params[:cc_type]
                                        })

        @credit_card = Spree::CreditCard.new(credit_card_params)
        # Can't mass assign these:
        @credit_card.cc_type = credit_card_params[:cc_type]
        @credit_card.last_digits = credit_card_params[:last_digits]
        @credit_card.user_id = @user.id
        if @credit_card.save
          render json: @credit_card, status: :ok
        else
          render json: "error saving credit card", status: 500
        end
      else
        render json: "error creating Stripe customer", status: 500
      end
    end

    def destroy
      if @credit_card.destroy
        redirect_to "/account"
      end
    end

    # Currently can only destroy the whole customer object
    def destroy_at_stripe
      if stripe_customer = Stripe::Customer.retrieve( @credit_card.gateway_customer_profile_id )
        stripe_customer.delete
      end
    end

  private
    def create_customer(token)
      Stripe::Customer.create(email: @user.email, source: token)
    end

    def format_credit_card_params(params_hash)
      { month: params_hash[:exp_month],
        year: params_hash[:exp_year],
        last_digits: params_hash[:last4]
      }
    end

    def set_user
      @user = spree_current_user
    end

    def set_credit_card
      @credit_card = Spree::CreditCard.find(params[:id])
    end
  end
end
