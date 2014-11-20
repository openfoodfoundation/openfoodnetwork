class EnterpriseSet < ModelSet
  def initialize(collection, attributes={})
    super(Enterprise, collection, nil, attributes)
  end
end
