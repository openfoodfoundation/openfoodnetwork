# frozen_string_literal: true

require 'spec_helper'

describe OmniauthCallbacksController, type: :request do
  OmniAuth.config.test_mode = true

  subject do
    post '/user/spree_user/auth/openid_connect/callback', params: { code: 'code123' }

    request.env['devise.mapping'] = Devise.mappings[:spree_user]
    request.env['omniauth.auth'] = omniauth_response
  end

  let(:user) { Spree::User.where(email: 'john@doe.com').first }

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

      expect(user).not_to be_nil
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

      expect(user).to be_nil
      expect(request.cookies[:omniauth_connect]).to be_nil
      expect(response.status).to eq(302)
    end
  end
end
