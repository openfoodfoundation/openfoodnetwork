# frozen_string_literal: true

# Link a Spree::Variant to an external DFC SuppliedProduct.
#
# We store an optional quantity to denote how many variant items are contained
# in an external wholesale product. For example, we may offer cans of beans
# on OFN and trigger wholesale orders of slabs of cans of beans which contain
# 12 cans each.
class SemanticLink < ApplicationRecord
  belongs_to :variant, class_name: "Spree::Variant"

  validates :semantic_id, presence: true
  validates :quantity, numericality: { greater_than: 0 }
end
