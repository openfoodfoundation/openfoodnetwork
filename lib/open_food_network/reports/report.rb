require 'open_food_network/reports/row'
require 'open_food_network/reports/rule'

module OpenFoodNetwork::Reports
  class Report
    # -- API
    def header
      @@header
    end

    def columns
      @@columns.to_a
    end

    def rules
      # Flatten linked list and return as hashes
      rules = []

      rule = @@rules_head
      while rule
        rules << rule
        rule = rule.next
      end

      rules.map &:to_h
    end


    # -- DSL
    def self.header(*columns)
      @@header = columns
    end

    def self.columns(&block)
      @@columns = Row.new
      @@columns.instance_eval(&block)
    end

    def self.organise(&block)
      @@rules_head = Rule.new
      @@rules_head.instance_eval(&block)
    end
  end
end
