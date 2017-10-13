require 'open_food_network/reports/row'
require 'open_food_network/reports/rule'

module OpenFoodNetwork::Reports
  class Report
    class_attribute :_header, :_columns, :_rules_head

    # -- API
    def header
      self._header
    end

    def columns
      self._columns.to_a
    end

    def rules
      # Flatten linked list and return as hashes
      rules = []

      rule = self._rules_head
      while rule
        rules << rule
        rule = rule.next
      end

      rules.map(&:to_h)
    end

    private

    def permissions
      @permissions ||= OpenFoodNetwork::Permissions.new(@user)
    end

    class << self
      # -- DSL
      def header(*columns)
        self._header = columns
      end

      def columns(&block)
        self._columns = Row.new
        Blockenspiel.invoke block, self._columns
      end

      def organise(&block)
        self._rules_head = Rule.new
        Blockenspiel.invoke block, self._rules_head
      end
    end
  end
end
