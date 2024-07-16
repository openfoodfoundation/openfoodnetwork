# frozen_string_literal: true

# An enterprise can opt-in for their data to be included in the affiliate_sales_data endpoint
#
module ConnectedApps
  class AffiliateSalesData < ConnectedApp
    def connect; end

    def disconnect; end
  end
end
