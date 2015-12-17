class VariantOverrideSet < ModelSet
  def initialize(collection, attributes={})
    super(VariantOverride, collection, attributes, nil,
          proc { |attrs| deletable?(attrs) } )
  end

  def deletable?(attrs)
    attrs['price'].blank? &&
    attrs['count_on_hand'].blank? &&
    attrs['sku'].nil? &&
    attrs['on_demand'].nil?
  end
end
