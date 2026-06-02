# frozen_string_literal: true

module DfcProvider
  # Backporting certifications to the DFC v1 Enterprise
  class Enterprise < DataFoodConsortium::ConnectorV1::Enterprise
    # @return [ICertification]
    attr_accessor :certifications

    def initialize(semantic_id, certifications: [], **properties)
      super(semantic_id, **properties)
      @certifications = certifications
      registerSemanticProperty("dfc-b:isCertifiedBy", &method("certifications"))
        .valueSetter = method("certifications=")
    end
  end
end
