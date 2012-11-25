class EnterpriseSet < ModelSet
  def initialize(attributes={})
    super(Enterprise, Enterprise.all, nil, attributes)
  end
end
