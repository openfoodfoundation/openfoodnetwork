# frozen_string_literal: true

# Service used to authorize the user on DCF Provider API
# It controls an OICD Access token and an enterprise.
class AuthorizationControl
  # Copied from: https://login.lescommuns.org/auth/realms/data-food-consortium/
  LES_COMMUNES_PUBLIC_KEY = <<~KEY
    -----BEGIN PUBLIC KEY-----
    MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAl68JGqAILFzoi/1+6siXXp2vylu+7mPjYKjKelTtHFYXWVkbmVptCsamHlY3jRhqSQYe6M1SKfw8D+uXrrWsWficYvpdlV44Vm7uETZOr1/XBOjpWOi1vLmBVtX6jFeqN1BxfE1PxLROAiGn+MeMg90AJKShD2c5RoNv26e20dgPhshRVFPUGru+0T1RoKyIa64z/qcTcTVD2V7KX+ANMweRODdoPAzQFGGjTnL1uUqIdUwSfHSpXYnKxXOsnPC3Mowkv8UIGWWDxS/yzhWc7sOk1NmC7pb+Cg7G8NKj+Pp9qQZnXF39Dg95ZsxJrl6fyPFvTo3zf9CPG/fUM1CkkwIDAQAB
    -----END PUBLIC KEY-----
  KEY

  def self.public_key
    OpenSSL::PKey::RSA.new(LES_COMMUNES_PUBLIC_KEY)
  end

  def initialize(request)
    @request = request
  end

  def user
    oidc_user || ofn_api_user || ofn_user
  rescue JWT::ExpiredSignature
    nil
  end

  private

  def oidc_user
    find_ofn_user(decode_token) if access_token
  end

  def ofn_api_user
    Spree::User.find_by(spree_api_key: ofn_api_token) if ofn_api_token.present?
  end

  def ofn_user
    @request.env['warden']&.user
  end

  def decode_token
    JWT.decode(
      access_token,
      self.class.public_key,
      true, { algorithm: "RS256" }
    ).first
  end

  def access_token
    @request.headers['Authorization'].to_s.split(' ').last
  end

  def ofn_api_token
    @request.headers["X-Api-Token"]
  end

  def find_ofn_user(payload)
    return if payload["email"].blank?

    Spree::User.find_by(uid: payload["email"])
  end
end
