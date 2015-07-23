require 'open_food_network/reports/row'

module OpenFoodNetwork::Reports
  class Rule
    attr_reader :next

    def group(&block)
      @group = block
    end

    def sort(&block)
      @sort = block
    end

    def summary_row(&block)
      @summary_row = Row.new
      @summary_row.instance_eval(&block)
    end

    def organise(&block)
      @next = Rule.new
      @next.instance_eval &block
    end

    def to_h
      h = {group_by: @group, sort_by: @sort}
      h.merge!({summary_columns: @summary_row.to_a}) if @summary_row
      h
    end
  end
end
