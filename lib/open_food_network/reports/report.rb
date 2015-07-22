require 'open_food_network/reports/row'

module OpenFoodNetwork::Reports
  class Report
    # -- API
    def header
      @@header
    end

    def columns
      @@columns.to_a
    end


    # -- DSL
    def self.header(*columns)
      @@header = columns
    end

    def self.columns(&block)
      @@columns = Row.new
      @@columns.instance_eval(&block)
    end
  end
end
