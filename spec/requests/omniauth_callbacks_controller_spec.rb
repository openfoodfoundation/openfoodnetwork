# frozen_string_literal: true

require 'spec_helper'

describe OmniauthCallbacksController, type: :request do
  include AuthenticationHelper

  OmniAuth.config.test_mode = true

  subject do
    login_as user
    post '/user/spree_user/auth/openid_connect/callback', params: { code: 'code123' }

    request.env['devise.mapping'] = Devise.mappings[:spree_user]
    request.env['omniauth.auth'] = omniauth_response
  end

  let(:user) { create(:user) }

  context 'when the omniauth setup is returning with an authorization' do
    let!(:omniauth_response) do
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
      subject

      expect(user.provider).to eq "openid_connect"
      expect(user.uid).to eq "john@doe.com"
      expect(request.cookies[:omniauth_connect]).to be_nil
      expect(response.status).to eq(302)
    end
  end

  context 'when the omniauth openid_connect is mocked with an error' do
    let!(:omniauth_response) do
      OmniAuth.config.mock_auth[:openid_connect] = :invalid_credentials
    end

    it 'fails with bad auth data' do
      subject

      expect(user.provider).to be_nil
      expect(user.uid).to be_nil
      expect(request.cookies[:omniauth_connect]).to be_nil
      expect(response.status).to eq(302)
    end
  end
end
