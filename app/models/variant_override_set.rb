class VariantOverrideSet < ModelSet
  def initialize(attributes={})
    super(VariantOverride, VariantOverride.all, attributes)
  end
end
