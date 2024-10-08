# frozen_string_literal: true

# An enterprise can be connected to other apps.
#
# Here we store keys and links to access the app.
class ConnectedApp < ApplicationRecord
  TYPES = ['discover_regen', 'affiliate_sales_data', 'vine'].freeze

  belongs_to :enterprise
  after_destroy :disconnect

  scope :discover_regen, -> { where(type: "ConnectedApp") }
  scope :affiliate_sales_data, -> { where(type: "ConnectedApps::AffiliateSalesData") }
  scope :vine, -> { where(type: "ConnectedApps::Vine") }

  scope :connecting, -> { where(data: nil) }
  scope :ready, -> { where.not(data: nil) }

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
