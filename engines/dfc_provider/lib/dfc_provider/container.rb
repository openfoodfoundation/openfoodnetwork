# frozen_string_literal: true

module DfcProvider
  # The DFC v2 mandates the use of LDP containers to list resources.
  # The Connector didn't provide a class for that, so we add it here.
  class Container
    include VirtualAssembly::Semantizer::SemanticObject

    SEMANTIC_TYPE = "ldp:Container"

    attr_accessor :members

    def initialize(semantic_id, members: [])
      super(semantic_id)
      self.semanticType = SEMANTIC_TYPE

      @members = members
      registerSemanticProperty("ldp:contains", &method("members")).valueSetter = method("members=")
    end
  end
end
