module OpenFoodNetwork::Reports
  class Rule
    attr_reader :next

    def group(&block)
      @group = block
    end

    def sort(&block)
      @sort = block
    end

    def organise(&block)
      @next = Rule.new
      @next.instance_eval &block
    end

    def to_h
      {group_by: @group, sort_by: @sort}
    end
  end
end
