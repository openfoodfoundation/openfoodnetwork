class VariantOverrideSet < ModelSet
  def initialize(attributes={})
    super(VariantOverride, VariantOverride.all, nil, attributes)
  end
end
