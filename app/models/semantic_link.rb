# frozen_string_literal: true

# Link a Spree::Variant to an external DFC SuppliedProduct.
class SemanticLink < ApplicationRecord
  belongs_to :variant, class_name: "Spree::Variant"

  validates :semantic_id, presence: true
end
