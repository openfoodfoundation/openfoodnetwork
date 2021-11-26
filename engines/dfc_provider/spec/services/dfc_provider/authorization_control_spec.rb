# frozen_string_literal: true

require 'spec_helper'

describe DfcProvider::AuthorizationControl do
  let!(:user) do
    create :user, email: 'testoidc@test.com',
                  provider: 'openid_connect',
                  uid: 'testoidc@test.com'
  end

  let(:jwk) do
    JWT::JWK.new(OpenSSL::PKey::RSA.new(2048), 'optional-kid')
  end

  let(:payload) { { email: 'testoidc@test.com' } }

  let(:access_token) do
    headers = { kid: jwk.kid }
    JWT.encode(payload, jwk.keypair, 'RS256', headers)
  end

  subject { DfcProvider::AuthorizationControl.new(access_token) }

  describe '.process' do
    context 'when the public and private keys are not paired' do
      before do
        allow_any_instance_of(DfcProvider::AuthorizationControl).
          to receive(:jwks_hash).
          and_return({ keys: [{ kty: 'RSA', kid: 'optional-kid', e: 'AQAB', n: 'xxxx' }] })
      end

      it 'raises an error' do
        expect{ subject.process }.to raise_error JWT::VerificationError
      end
    end

    context 'when the public and private keys are paired' do
      before do
        allow_any_instance_of(DfcProvider::AuthorizationControl).
          to receive(:jwks_hash).
          and_return({ keys: [jwk.export] })
      end

      context 'when the token is linked to an existing user' do
        it 'finds the user' do
          expect(subject.process).to eq(user)
        end
      end

      context 'when the token is not linked to an existing user' do
        let(:payload) { { email: nil } }

        it 'does not find the user' do
          expect{ subject.process }.to raise_error(RuntimeError, 'Email Not Found')
        end
      end
    end
  end
end
