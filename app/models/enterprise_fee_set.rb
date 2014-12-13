class EnterpriseFeeSet < ModelSet
  def initialize(attributes={})
    super(EnterpriseFee, EnterpriseFee.all,
          attributes,
          proc { |attrs| attrs[:name].blank? })
  end
end
