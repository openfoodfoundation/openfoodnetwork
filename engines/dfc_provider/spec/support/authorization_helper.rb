# frozen_string_literal: true

module AuthorizationHelper
  def authorise(email)
    token = allow_token_for(email: email)
    request.headers["Authorization"] = "JWT #{token}"
  end

  def allow_token_for(payload)
    private_key = OpenSSL::PKey::RSA.generate 2048
    allow(DfcProvider::AuthorizationControl).to receive(:public_key).
      and_return(private_key.public_key)

    JWT.encode(payload, private_key, "RS256")
  end
end
