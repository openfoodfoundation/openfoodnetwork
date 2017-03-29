class Api::Admin::Reports::VariantSerializer < ActiveModel::Serializer
  attributes :id, :options_text, :sku
end
