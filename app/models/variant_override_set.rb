class VariantOverrideSet < ModelSet
  def initialize(collection, attributes={})
    super(VariantOverride, collection, attributes, nil,
          proc { |attrs| attrs['price'].blank? && attrs['count_on_hand'].blank? } )
  end
end
