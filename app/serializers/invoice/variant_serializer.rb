# frozen_string_literal: false

class Invoice
  class VariantSerializer < ActiveModel::Serializer
    attributes :id, :display_name, :options_text
    has_one :product, serializer: Invoice::ProductSerializer
    has_one :enterprise, serializer: Invoice::EnterpriseSerializer
  end
end
