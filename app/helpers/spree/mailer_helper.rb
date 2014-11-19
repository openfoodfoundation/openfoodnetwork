module Spree
  module MailerHelper
    def email_asset_url(asset)
      URI.join(root_url, asset_path(asset)).to_s
    end
  end
end