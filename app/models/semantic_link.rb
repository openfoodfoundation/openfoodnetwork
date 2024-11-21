# frozen_string_literal: true

# Link a Spree::Variant to an external DFC SuppliedProduct.
class SemanticLink < ApplicationRecord
  self.ignored_columns += [:variant_id]

  belongs_to :subject, polymorphic: true

  validates :semantic_id, presence: true
end
