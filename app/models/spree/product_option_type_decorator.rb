Spree::ProductOptionType.class_eval do
  after_destroy :remove_option_values

  def remove_option_values
    self.product.variants_including_master.each do |variant|
      option_values = variant.option_values.where(option_type_id: self.option_type)
      variant.option_values.destroy(*option_values)
    end
  end
end
