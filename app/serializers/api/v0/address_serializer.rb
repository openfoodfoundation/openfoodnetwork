class Api::V0::AddressSerializer < Api::V0::RablSerializer
  def template
    "spree/api/addresses/show".freeze
  end
end
