# frozen_string_literal: true

require 'spec_helper'

# Devise calls OmniauthCallbacksController for OpenID Connect callbacks.
describe '/user/spree_user/auth/openid_connect/callback', type: :request do
  include AuthenticationHelper

  let(:user) { create(:user) }
  let(:params) { { code: 'code123' } }

  before do
    OmniAuth.config.test_mode = true
    login_as user
  end

  def request!
    post(self.class.top_level_description, params:)
  end

  context 'when the omniauth setup is returning with an authorization' do
    # The auth hash data has been observed by connecting to the Keycloak server
    # https://login.lescommuns.org/.
    before do
      OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
        JSON.parse(file_fixture("omniauth.auth.json").read)
      )
    end

    it 'is successful' do
      expect { request! }.to change { OidcAccount.count }.by(1)

      account = OidcAccount.last
      expect(account.provider).to eq "openid_connect"
      expect(account.uid).to eq "ofn@example.com"
      expect(response.status).to eq(302)
    end
  end

  context 'when the omniauth openid_connect is mocked with an error' do
    before do
      OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
    end

    it 'fails with bad auth data' do
      expect { request! }.not_to change { OidcAccount.count }

      expect(response.status).to eq(302)
    end
  end
end
