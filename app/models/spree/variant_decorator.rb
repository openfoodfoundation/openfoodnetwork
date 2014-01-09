Spree::Variant.class_eval do
  attr_accessible :unit_value, :unit_description

  validates_presence_of :unit_value,
                        if: -> v { %w(weight volume).include? v.product.variant_unit },
                        unless: :is_master

  validates_presence_of :unit_description,
                        if: -> v { v.product.variant_unit.present? && v.unit_value.nil? },
                        unless: :is_master


  def delete_unit_option_values
    self.option_values.where('option_type_id IN (?)',
                             Spree::Product.all_variant_unit_option_types).destroy_all
  end

end
