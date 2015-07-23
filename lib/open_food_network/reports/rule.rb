require 'open_food_network/reports/row'

module OpenFoodNetwork::Reports
  class Rule
    include Blockenspiel::DSL
    attr_reader :next

    def group(&block)
      @group = block
    end

    def sort(&block)
      @sort = block
    end

    def summary_row(&block)
      @summary_row = Row.new
      Blockenspiel.invoke block, @summary_row
    end

    def organise(&block)
      @next = Rule.new
      Blockenspiel.invoke block, @next
    end

    def to_h
      h = {group_by: @group, sort_by: @sort}
      h.merge!({summary_columns: @summary_row.to_a}) if @summary_row
      h
    end
  end
end
