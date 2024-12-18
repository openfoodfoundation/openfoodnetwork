# frozen_string_literal: true

class DfcCatalog
  def initialize(graph)
    @graph = graph
  end

  def products
    @products ||= @graph.select do |subject|
      subject.is_a? DataFoodConsortium::Connector::SuppliedProduct
    end
  end
end
