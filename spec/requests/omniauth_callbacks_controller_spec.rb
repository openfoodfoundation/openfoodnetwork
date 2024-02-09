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
    before do
      OmniAuth.config.mock_auth[:openid_connect] = OmniAuth::AuthHash.new(
        'provider' => 'openid_connect',
        'uid' => 'john@doe.com',
        'info' => {
          'email' => 'john@doe.com',
          'first_name' => 'John',
          'last_name' => 'Doe'
        }
      )
    end

    it 'is successful' do
      request!

      expect(user.provider).to eq "openid_connect"
      expect(user.uid).to eq "john@doe.com"
      expect(response.status).to eq(302)
    end
  end

  context 'when the omniauth openid_connect is mocked with an error' do
    before do
      OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
    end

    it 'fails with bad auth data' do
      request!

      expect(user.provider).to be_nil
      expect(user.uid).to be_nil
      expect(response.status).to eq(302)
    end
  end
end
