Spree::Variant.class_eval do
  attr_accessible :unit_value, :unit_description

  validates_presence_of :unit_value,
                        if: -> v { %w(weight volume).include? v.product.variant_unit },
                        unless: :is_master

  validates_presence_of :unit_description,
                        if: -> v { v.product.variant_unit.present? && v.unit_value.nil? },
                        unless: :is_master

  after_save :update_units

  def delete_unit_option_values
    ovs = self.option_values.where('option_type_id IN (?)',
                                   Spree::Product.all_variant_unit_option_types)
    self.option_values.destroy ovs
  end


  private

  def update_units
    option_type = self.product.variant_unit_option_type

    if option_type
      name = option_value_name
      ov = Spree::OptionValue.where(option_type_id: option_type, name: name, presentation: name).first || Spree::OptionValue.create!({option_type: option_type, name: name, presentation: name}, without_protection: true)
      option_values << ov #unless option_values.include? ov
    end
  end

  def option_value_name
    '10 g foo'
  end

end
