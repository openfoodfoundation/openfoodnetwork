module OpenFoodWeb
  class GroupBuyReport
    def initialize orders
      @orders = orders
    end

    def header
      ["Supplier", "Product", "Unit Size", "Variant", "Weight", "Total Ordered", "Total Max"]
    end
  end
end