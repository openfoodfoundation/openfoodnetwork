# frozen_string_literal: true

if defined? DataFoodConsortium::Connector::Coordination
  ActiveSupport::Deprecation.warn <<~TEXT
    DataFoodConsortium::Connector::Coordination is now available.
    Please replace your own implementation with the official class.
  TEXT
end

module DfcProvider
  class Coordination
    include VirtualAssembly::Semantizer::SemanticObject

    SEMANTIC_TYPE = "dfc-b:Coordination"

    attr_accessor :coordinator

    def initialize(semantic_id, coordinator: nil)
      super(semantic_id)

      self.semanticType = SEMANTIC_TYPE

      @coordinator = coordinator
      registerSemanticProperty("dfc-b:coordinatedBy", &method("coordinator"))
        .valueSetter = method("coordinator=")
    end
  end
end
