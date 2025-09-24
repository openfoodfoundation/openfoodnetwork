# frozen_string_literal: true

# Authorised user or client using the API
class ApiUser
  PLATFORMS = {
    'cqcm-dev' => {
      id: "https://api.proxy-dev.cqcm.startinblox.com/profile",
      tokens: "https://kc.cqcm.startinblox.com/realms/startinblox/protocol/openid-connect/token",
    },
    'cqcm-stg' => {
      id: "https://api.proxy-stg.cqcm.startinblox.com/profile",
      tokens: "https://kc.cqcm.startinblox.com/realms/startinblox/protocol/openid-connect/token",
    },
    'cqcm' => {
      id: "https://carte.cqcm.coop/profile",
      tokens: "https://authentification.cqcm.coop/realms/cqcm/protocol/openid-connect/token",
    },
  }.freeze
  CLIENT_MAP = PLATFORMS.keys.index_by { |key| PLATFORMS.dig(key, :id) }.freeze

  def self.platform_url(platform)
    PLATFORMS.dig(platform, :id)
  end

  def self.token_endpoint(platform)
    PLATFORMS.dig(platform, :tokens)
  end

  def self.from_client_id(client_id)
    id = CLIENT_MAP[client_id]

    new(id) if id
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def admin?
    false
  end

  def customers
    Customer.none
  end

  def enterprises
    Enterprise.where(dfc_permissions: permissions("ReadEnterprise"))
  end

  def permissions(scope)
    DfcPermission.where(grantee: id, scope:)
  end
end
