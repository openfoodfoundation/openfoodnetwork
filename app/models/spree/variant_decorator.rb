require 'open_food_network/option_value_namer'

Spree::Variant.class_eval do
  has_many :exchange_variants, dependent: :destroy
  has_many :exchanges, through: :exchange_variants

  attr_accessible :unit_value, :unit_description, :images_attributes, :display_as, :display_name
  accepts_nested_attributes_for :images

  validates_presence_of :unit_value,
                        if: -> v { %w(weight volume).include? v.product.variant_unit },
                        unless: :is_master

  validates_presence_of :unit_description,
                        if: -> v { v.product.variant_unit.present? && v.unit_value.nil? },
                        unless: :is_master

  before_validation :update_weight_from_unit_value
  after_save :update_units

  scope :not_deleted, where(deleted_at: nil)
  scope :in_stock, where('spree_variants.count_on_hand > 0 OR spree_variants.on_demand=?', true)


  def price_with_fees(distributor, order_cycle)
    price + fees_for(distributor, order_cycle)
  end

  def fees_for(distributor, order_cycle)
    order_cycle.fees_for(self, distributor)
  end


  # Copied and modified from Spree::Variant
  def options_text
    values = self.option_values.joins(:option_type).order("#{Spree::OptionType.table_name}.position asc")

    values.map! &:presentation    # This line changed

    values.to_sentence({ :words_connector => ", ", :two_words_connector => ", " })
  end

  def delete_unit_option_values
    ovs = self.option_values.where(option_type_id: Spree::Product.all_variant_unit_option_types)
    self.option_values.destroy ovs
  end

  def full_name
    return unit_to_display if display_name.blank?
    display_name + " (" + unit_to_display + ")"
  end

  def name_to_display
    return product.name if display_name.blank?
    display_name
  end

  def unit_to_display
    return options_text if display_as.blank?
    display_as
  end


  def update_units
    delete_unit_option_values

    option_type = self.product.variant_unit_option_type
    if option_type
      name = option_value_name
      ov = Spree::OptionValue.where(option_type_id: option_type, name: name, presentation: name).first || Spree::OptionValue.create!({option_type: option_type, name: name, presentation: name}, without_protection: true)
      option_values << ov
    end
  end

  def delete
    transaction do
      self.update_column(:deleted_at, Time.now)
      ExchangeVariant.where(variant_id: self).destroy_all
    end
  end


  private

  def update_weight_from_unit_value
    self.weight = unit_value / 1000 if self.product.variant_unit == 'weight' && unit_value.present?
  end

  def option_value_name
    if display_as.present?
      display_as
    else
      option_value_namer = OpenFoodNetwork::OptionValueNamer.new self
      option_value_namer.name
    end
  end
end
