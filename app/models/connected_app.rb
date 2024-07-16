# frozen_string_literal: true

# An enterprise can be connected to other apps.
#
# Here we store keys and links to access the app.
class ConnectedApp < ApplicationRecord
  belongs_to :enterprise
  after_destroy :disconnect

  scope :discover_regen, -> { where(type: "ConnectedApp") }
  scope :affiliate_sales_data, -> { where(type: "ConnectedApps::AffiliateSalesData") }

  def connecting?
    data.nil?
  end

  def ready?
    !connecting?
  end

  def connect(api_key:, channel:)
    ConnectAppJob.perform_later(self, api_key, channel:)
  end

  def disconnect
    WebhookDeliveryJob.perform_later(
      data["destroy"],
      "disconnect-app",
      nil
    )
  end
end
