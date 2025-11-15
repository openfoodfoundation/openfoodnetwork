# frozen_string_literal: true

# Authorize the user on the DFC API
#
# It controls an OICD Access token and an enterprise.
class AuthorizationControl
  PUBLIC_KEYS = {
    "https://login.lescommuns.org/auth/realms/data-food-consortium" => <<~KEY,
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAl68JGqAILFzoi/1+6siXXp2vylu+7mPjYKjKelTtHFYXWVkbmVptCsamHlY3jRhqSQYe6M1SKfw8D+uXrrWsWficYvpdlV44Vm7uETZOr1/XBOjpWOi1vLmBVtX6jFeqN1BxfE1PxLROAiGn+MeMg90AJKShD2c5RoNv26e20dgPhshRVFPUGru+0T1RoKyIa64z/qcTcTVD2V7KX+ANMweRODdoPAzQFGGjTnL1uUqIdUwSfHSpXYnKxXOsnPC3Mowkv8UIGWWDxS/yzhWc7sOk1NmC7pb+Cg7G8NKj+Pp9qQZnXF39Dg95ZsxJrl6fyPFvTo3zf9CPG/fUM1CkkwIDAQAB
      -----END PUBLIC KEY-----
    KEY

    "https://kc.cqcm.startinblox.com/realms/startinblox" => <<~KEY,
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqtvdb3BdHoLnNeMLaWd7nugPwdRAJJpdSySTtttEQY2/v1Q3byJ/kReSNGrUNkPVkOeDN3milgN5Apz+sNCwbtzOCulyFMmvuIOZFBqz5tcgwjZinSwpGBXpn6ehXyCET2LlcfLYAPA9axtaNg9wBLIHoxIPWpa2LcZstogyZY/yKUZXQTDqM5B5TyUkPN89xHFdq8SQuXPasbpYl7mGhZHkTDHiKZ9VK7K5tqsEZTD9dCuTGMKsthbOrlDnc9bAJ3PyKLRdib21Y1GGlTozo4Y/1q448E/DFp5rVC6jG6JFnsEnP0WVn+6qz7yxI7IfUU2YSAGgtGYaQkWtEfED0QIDAQAB
      -----END PUBLIC KEY-----
    KEY

    "https:///authentification.cqcm.coop/realms/cqcm" => <<~KEY,
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAhz7dK3xQAWL+u++E/64T1OHEvnFrZRLzgCmw0leib3JL/XbaE4Jbd3fs2+zc3+dCwvCuLEKKO9Hc9wg79ifjtMKFfZDE1Ba+qhw7J9tYnu7TBtaxKuWUCdtwuultEdW+NFndaUvhD/TdyjDkRiO98mgvUbm2A3q/zyDmoUpR2IEfevkMSz8MnxUo1bDTJIyoYoKwnbToI1E9RVx2uYsYKk24Pfd+r6oTbi7TxA6Ia4EiREFki2gNIAdp66IqF0Gxyd+nGlkIbQGrW+9xynU4ar3ZNq/P8EZFdO57AdEvC3ZAzpTvOVcQ0cQ4XbRSYWQHyZ8jnjggpeddTGSqVlgx1wIDAQAB
      -----END PUBLIC KEY-----
    KEY

    "https://login.fooddatacollaboration.org.uk/realms/dev" => <<~KEY,
      -----BEGIN PUBLIC KEY-----
      MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAihRLCBeT16xTp8K5AD59CcknSWOTRzRMrNaFElOEGE8RJBy3SGAGQZtd6RCI6et44CR2pBnCmFg7In4ufTszSsix+bIagp6ljBybAY1+Z8kQLpDukAVsrTIeLoqH7m7cJ/5B2ije5TS8ZGH0gZMQO46CTga9LV9IwyjeWcZx6iQor0zDFQJ6caq/IMV8l6+kTjPK2F7Em6f4SzhfOOJauuO8C9mQkCftDudeyfnEdF05MAUhch4CP+E26CZcSdrM1uOmOH9l0sbMdDijTjZCTeI1BO27T1ap1Ix7w5/U4JUWVmGTzPkOTgvEMiXMAitB5RetCicGiMop34nhDOJRwwIDAQAB
      -----END PUBLIC KEY-----
    KEY
  }.freeze

  def self.public_key(token)
    unverified_payload = JWT.decode(token, nil, false, { algorithm: "RS256" }).first
    key = PUBLIC_KEYS[unverified_payload["iss"]]
    OpenSSL::PKey::RSA.new(key)
  end

  def initialize(request)
    @request = request
  end

  def user
    oidc_user || ofn_api_user || ofn_user
  rescue JWT::DecodeError
    nil
  end

  private

  def oidc_user
    return unless access_token

    payload = decode_token

    find_ofn_user(payload) || client_user(payload)
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
      self.class.public_key(access_token),
      true, { algorithm: "RS256" }
    ).first
  end

  def access_token
    @request.headers['Authorization'].to_s.split.last
  end

  def ofn_api_token
    @request.headers["X-Api-Token"]
  end

  def find_ofn_user(payload)
    return if payload["email"].blank?

    OidcAccount.find_by(uid: payload["email"])&.user
  end

  def client_user(payload)
    ApiUser.from_client_id(payload["client_id"])
  end
end
