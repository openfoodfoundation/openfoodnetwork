class VariantOverrideSet < ModelSet
  def initialize(attributes={})
    super(VariantOverride, VariantOverride.all, attributes, nil,
          proc { |attrs| attrs['price'].blank? && attrs['count_on_hand'].blank? } )
  end
end
