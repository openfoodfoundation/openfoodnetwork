class EnterpriseFeeSet < ModelSet
  def initialize(attributes={})
    super(EnterpriseFee, EnterpriseFee.all,
          proc { |attrs| attrs[:enterprise_id].blank? },
          attributes)
  end
end
