require 'spec_helper'

describe Admin::StripeAccountsController, type: :controller do
  it "deletes Stripe accounts in response to a webhook" do
    # https://stripe.com/docs/api#retrieve_event
    allow(controller).to receive(:fetch_event_from_stripe)
      .and_return({
      "id" => "evt_18zt9YFBE7f7kItLg9f343bn",
      "object" => "event",
      "created" => 1475350088,
      "data" => {
          "id" => "webhook_id",
          "name" => "OFN",
          "object" => "application"
      },
      "type" => "account.application.deauthorized"
    })
    account = create(:stripe_account, stripe_user_id: "webhook_id")
    post 'destroy_from_webhook'
    expect(StripeAccount.all).not_to include account

  end

end
