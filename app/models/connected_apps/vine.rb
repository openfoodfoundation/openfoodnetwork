# frozen_string_literal: true

# An enterprise can opt-in to use VINE API to manage vouchers
#
module ConnectedApps
  class Vine < ConnectedApp
    def connect(api_key:, vine_api:, **_opts)
      response = vine_api.my_team

      return update data: { api_key: } if response.success?

      errors.add(:base, I18n.t("activerecord.errors.models.connected_apps.vine.api_request_error"))

      false
    end

    def disconnect; end
  end
end
