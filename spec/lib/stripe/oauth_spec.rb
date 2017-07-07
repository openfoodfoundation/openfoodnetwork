require 'spec_helper'
require 'stripe/oauth'

module Stripe
  describe OAuth do
    describe "contructing an authorization url" do
      let(:enterprise_id) { "ent_id" }

      before do
        allow(OAuth.client).to receive(:id) { 'abc' }
      end

      it "builds a url with all of the necessary params" do
        url = OAuth.authorize_url(enterprise_id)
        uri = URI.parse(url)
        params = CGI.parse(uri.query)
        expect(params.keys).to include 'client_id', 'response_type', 'state', 'scope'
        expect(params["state"]).to eq [OAuth.send(:jwt_encode, enterprise_id: enterprise_id)]
        expect(uri.scheme).to eq 'https'
        expect(uri.host).to eq 'connect.stripe.com'
        expect(uri.path).to eq '/oauth/authorize'
      end
    end
  end
end
