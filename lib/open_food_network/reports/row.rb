module OpenFoodNetwork::Reports
  class Row
    include Blockenspiel::DSL

    def initialize
      @columns = []
    end

    def column(&block)
      @columns << block
    end

    def to_a
      @columns
    end
  end
end
