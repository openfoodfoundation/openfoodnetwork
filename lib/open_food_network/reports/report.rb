module OpenFoodNetwork::Reports
  class Report
    # -- API
    def header
      @@header
    end


    # -- DSL
    def self.header(*columns)
      @@header = columns
    end
  end
end
