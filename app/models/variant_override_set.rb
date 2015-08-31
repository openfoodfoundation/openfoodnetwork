class VariantOverrideSet < ModelSet
  def initialize(collection, attributes={})
    super(VariantOverride, collection, attributes, nil,
          # I have no idea what this does but had to add all fields to get it to create a new VO when only a new field was changed.
          # i.e. a field unique to Variant Override (default_stock and reset) and not present in Variant.
          proc { |attrs| attrs['price'].blank? && attrs['count_on_hand'].blank? && attrs['default_stock'].blank? && attrs['enable_reset'].blank?} )
  end
end
