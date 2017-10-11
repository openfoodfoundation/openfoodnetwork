class StripeController < BaseController
  def deauthorize
    # TODO is there a sensible way to confirm this webhook call is actually from Stripe?
    event = Stripe::Event.construct_from(params)
    return render nothing: true, status: 204 unless event.type == "account.application.deauthorized"

    destroyed = StripeAccount.where(stripe_user_id: event.account).destroy_all
    if destroyed.any?
      render text: "Account #{event.account} deauthorized", status: 200
    else
      render nothing: true, status: 204
    end
  end
end
