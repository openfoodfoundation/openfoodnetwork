# frozen_string_literal: true

require "open_food_network/oidc_secrets"

RSpec.describe OpenFoodNetwork::OidcSecrets do
  let(:pem) { OpenSSL::PKey::RSA.new(2048).to_pem }
  let(:previous_pem) { OpenSSL::PKey::RSA.new(2048).to_pem }
  let(:env_without_secrets) {
    ENV.to_h.except("OIDC_SIGNING_KEY", "OIDC_SIGNING_KEY_PREVIOUS", "OIDC_PAIRWISE_SECRET")
  }

  describe ".signing_keys" do
    it "reads the active and previous keys, with escaped line breaks" do
      stub_const("ENV", env_without_secrets.merge(
                          "OIDC_SIGNING_KEY" => pem.gsub("\n", '\n'),
                          "OIDC_SIGNING_KEY_PREVIOUS" => previous_pem,
                        ))

      expect(described_class.signing_keys).to eq [pem, previous_pem]
    end

    it "rejects a key that can't sign RS256 tokens" do
      ec_pem = OpenSSL::PKey::EC.generate("prime256v1").to_pem
      stub_const("ENV", env_without_secrets.merge("OIDC_SIGNING_KEY" => ec_pem))

      expect { described_class.signing_keys }.to raise_error ArgumentError, /RSA private/
    end

    it "uses a generated key in development and test" do
      stub_const("ENV", env_without_secrets)

      keys = described_class.signing_keys

      expect(keys.size).to eq 1
      expect(OpenSSL::PKey::RSA.new(keys.first)).to be_private
    end

    it "has no key in production without configuration" do
      stub_const("ENV", env_without_secrets)
      allow(Rails.env).to receive(:local?).and_return(false)

      expect(described_class.signing_keys).to be_empty
    end
  end

  describe ".pairwise_secret" do
    it "reads the configured secret" do
      stub_const("ENV", env_without_secrets.merge("OIDC_PAIRWISE_SECRET" => "s3cret"))

      expect(described_class.pairwise_secret).to eq "s3cret"
    end

    it "is required in production" do
      stub_const("ENV", env_without_secrets)
      allow(Rails.env).to receive(:local?).and_return(false)

      expect { described_class.pairwise_secret }.to raise_error KeyError
    end
  end
end
