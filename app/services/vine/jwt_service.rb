# frozen_string_literal: true

module Vine
  class JwtService
    ALGORITHM = "HS256"
    ISSUER = "openfoodnetwork"

    def initialize(secret: )
      @secret = secret
    end

    def generate_token
      generation_time = Time.zone.now
      payload = {
        iss: ISSUER,
        iat: generation_time.to_i,
        exp: (generation_time + 1.minute).to_i,
      }

      JWT.encode(payload, @secret, ALGORITHM)
    end
  end
end
