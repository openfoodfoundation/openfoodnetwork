class EnterpriseSet < ModelSet
  def initialize(attributes={})
    super(Enterprise.all, attributes)
  end
end
