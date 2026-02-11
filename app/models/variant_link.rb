# frozen_string_literal: true

class VariantLink < ApplicationRecord
  belongs_to :source_variant, class_name: 'Spree::Variant', touch: true
  belongs_to :linked_variant, class_name: 'Spree::Variant', touch: true
end