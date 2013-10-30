class EnterpriseFeeSet < ModelSet
  def initialize(attributes={})
    super(EnterpriseFee, EnterpriseFee.all,
          proc { |attrs| attrs[:name].blank? },
          attributes)
  end
end
