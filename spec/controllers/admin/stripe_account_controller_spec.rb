require 'spec_helper'

describe Admin::StripeAccountsController, type: :controller do

  it "deletes Stripe accounts in response to a webhook" do
    # https://stripe.com/docs/api#retrieve_event
    allow(controller).to receive(:fetch_event_from_stripe)
      .and_return(Stripe::Event.construct_from({"id"=>"evt_wrfwg4323fw",
                   "object"=>"event",
                   "api_version"=>nil,
                   "created"=>1484870684,
                   "data"=>
                    {"object"=>
                      {"id"=>"application_id",
                       "object"=>"application",
                       "name"=>"Open Food Network UK"}},
                   "livemode"=>false,
                   "pending_webhooks"=>1,
                   "request"=>nil,
                   "type"=>"account.application.deauthorized",
                   "user_id"=>"webhook_id"}))
    account = create(:stripe_account, stripe_user_id: "webhook_id")
    post 'destroy_from_webhook', {"id"=>"evt_wrfwg4323fw",
                                   "object"=>"event",
                                   "api_version"=>nil,
                                   "created"=>1484870684,
                                   "data"=>
                                    {"object"=>
                                      {"id"=>"ca_9ByaSyyyXj5O73DWisU0KLluf0870Vro",
                                       "object"=>"application",
                                       "name"=>"Open Food Network UK"}},
                                   "livemode"=>false,
                                   "pending_webhooks"=>1,
                                   "request"=>nil,
                                   "type"=>"account.application.deauthorized",
                                   "user_id"=>"webhook_id"}
    expect(StripeAccount.all).not_to include account

  end

end
