class ProductFilterer
  def initialize(products)
    @products = products
  end

  def call
    filter(@products)
  end

  private

  def filter_json(products)
    if applicator.rules.any?
      applicator.filter!(products)
    else
      products
    end
  end

  def applicator
    return @applicator unless @applicator.nil?
    @applicator = OpenFoodNetwork::TagRuleApplicator.new(current_distributor,
                                                         "FilterProducts",
                                                         current_customer.andand.tag_list)
  end
end
