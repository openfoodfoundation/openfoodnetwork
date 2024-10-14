# frozen_string_literal: true

# An enterprise can opt-in to use VINE API to manage vouchers
#
module ConnectedApps
  class Vine < ConnectedApp
    encrypts :data

    def connect(api_key:, secret:, vine_api:, **_opts)
      response = vine_api.my_team

      return update data: { api_key:, secret: } if response.success?

      errors.add(:base, I18n.t("activerecord.errors.models.connected_apps.vine.api_request_error"))

      false
    end

    def disconnect; end
  end
end
