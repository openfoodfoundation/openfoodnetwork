# frozen_string_literal: true

# Service used to authorize the user on DCF Provider API
# It controls an OICD Access token and an enterprise.
module DfcProvider
  class AuthorizationControl
    def initialize(access_token)
      @access_token = access_token
    end

    def process
      decode_token
      find_ofn_user
    end

    private

    def decode_token
      rsa_public = OpenSSL::PKey::RSA.new(DFC_PUBLIC_KEY)
      data = JWT.decode(
        @access_token,
        rsa_public, true, { algorithm: 'RS256' }
      )

      @header = data.last
      @payload = data.first
    end

    def find_ofn_user
      Spree::User.where(email: @payload['email']).first
    end

    DFC_PUBLIC_KEY = "-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnL0KaRkAKtWcc0TnwtlNVQ58PsB8guPirh1OCnNUqr71q3zyAqh5t6oWIRCTS5eqr2zhb/Je3QOeX2l0tGZ2YVQIBhvIGHcYfpMvrT+Loqsh3rHYiRLXs+YvUIM0tyWeQlpDMeqQ/t1G61FcF+HsiOBRvhaho7e+cV1hO1QvzcoxeMleexPdK+dnL4qHGKELf1oZmvFKcUAHG8IOcoxJn3KYdJsEbRj3jTAliTCXxGXmY++0c48pSV2iaOhxxlgR4AZTH+fSveAosGSPSYDYL9xVCyrRHFRgkHlIcw61hF6YyEE5G5b4MEumafBiLKZ9HJfjAhZv3kcD72nTGgJrMQIDAQAB
-----END PUBLIC KEY-----"
  end
end
