class Invoice::VariantSerializer < ActiveModel::Serializer
  attributes :display_name, :options_text
  has_one :product, serializer: Invoice::ProductSerializer
end