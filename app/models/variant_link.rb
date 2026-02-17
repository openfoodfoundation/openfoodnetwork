# frozen_string_literal: true

class VariantLink < ApplicationRecord
  belongs_to :source_variant, class_name: 'Spree::Variant', touch: true
  belongs_to :target_variant, class_name: 'Spree::Variant', touch: true
end
