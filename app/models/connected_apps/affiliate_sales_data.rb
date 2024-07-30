# frozen_string_literal: true

# An enterprise can opt-in for their data to be included in the affiliate_sales_data endpoint
#
module ConnectedApps
  class AffiliateSalesData < ConnectedApp
    def connect(_opts)
      update! data: true # not-nil value indicates it is ready
    end

    def disconnect; end
  end
end
