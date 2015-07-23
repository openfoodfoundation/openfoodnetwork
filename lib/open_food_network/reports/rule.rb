module OpenFoodNetwork::Reports
  class Rule
    def group(&block)
      @group = block
    end

    def sort(&block)
      @sort = block
    end

    def to_h
      {group_by: @group, sort_by: @sort}
    end

  end
end
