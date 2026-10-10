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

    it "generates a key once in development and test" do
      stub_const("ENV", env_without_secrets)
      key_path = Pathname(Dir.mktmpdir).join("oidc_signing_key.pem")
      stub_const("#{described_class}::LOCAL_KEY_PATH", key_path)

      keys = described_class.signing_keys

      expect(keys.size).to eq 1
      expect(OpenSSL::PKey::RSA.new(keys.first)).to be_private
      expect(key_path.read).to eq keys.first
      expect(described_class.signing_keys).to eq keys
    end

    it "has no key in production without configuration" do
      stub_const("ENV", env_without_secrets)
      allow(Rails.env).to receive(:local?).and_return(false)

      expect(described_class.signing_keys).to be_empty
    end
  end

  describe ".missing" do
    it "lists the secrets that production needs and doesn't have" do
      stub_const("ENV", env_without_secrets.merge("OIDC_PAIRWISE_SECRET" => "s3cret"))

      expect(described_class.missing).to eq ["OIDC_SIGNING_KEY"]
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
