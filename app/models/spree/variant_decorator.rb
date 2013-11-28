Spree::Variant.class_eval do
  validates_presence_of :unit_value,
                        if: -> v { %w(weight volume).include? v.product.variant_unit },
                        unless: :is_master

  validates_presence_of :unit_description,
                        if: -> v { v.product.variant_unit.present? && v.unit_value.nil? },
                        unless: :is_master
end
