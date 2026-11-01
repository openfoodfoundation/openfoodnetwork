# frozen_string_literal: true

module OpenFoodNetwork
  # Secrets of the OpenID Connect provider, from the environment.
  #
  # OIDC_SIGNING_KEY is the RSA private key signing ID tokens (PEM, line breaks
  # may be written as "\n"). During a rotation, the retired key goes to
  # OIDC_SIGNING_KEY_PREVIOUS so that its public part stays published until the
  # ID tokens it signed have expired.
  #
  # OIDC_PAIRWISE_SECRET derives the user identifier given to each application.
  # Changing it changes every identifier, so it must never be rotated.
  #
  # Development and test environments work without them.
  module OidcSecrets
    LOCAL_KEY_PATH = Rails.root.join("tmp/oidc_signing_key.pem")

    def self.signing_keys
      keys = %w[OIDC_SIGNING_KEY OIDC_SIGNING_KEY_PREVIOUS].filter_map do |name|
        ENV[name].presence&.gsub('\n', "\n")
      end
      keys = [local_signing_key] if keys.empty? && Rails.env.local?
      keys.each { |pem| ensure_rsa_private_key(pem) }
    end

    def self.pairwise_secret
      ENV["OIDC_PAIRWISE_SECRET"].presence ||
        (Rails.env.local? && Rails.application.key_generator.generate_key("oidc pairwise")) ||
        raise(KeyError, "OIDC_PAIRWISE_SECRET is not set")
    end

    def self.missing
      %w[OIDC_SIGNING_KEY OIDC_PAIRWISE_SECRET].select { |name| ENV[name].blank? }
    end

    def self.ensure_rsa_private_key(pem)
      key = OpenSSL::PKey.read(pem)
      return if key.is_a?(OpenSSL::PKey::RSA) && key.private?

      raise ArgumentError, "OIDC signing keys must be RSA private keys"
    end

    def self.local_signing_key
      unless LOCAL_KEY_PATH.exist?
        LOCAL_KEY_PATH.dirname.mkpath
        temporary_path = "#{LOCAL_KEY_PATH}.#{Process.pid}"
        File.write(temporary_path, OpenSSL::PKey::RSA.new(2048).to_pem)
        File.rename(temporary_path, LOCAL_KEY_PATH)
      end
      LOCAL_KEY_PATH.read
    end
  end
end
