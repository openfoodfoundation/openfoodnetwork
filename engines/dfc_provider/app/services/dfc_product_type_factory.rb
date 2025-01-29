# frozen_string_literal: true

class DfcProductTypeFactory
  def self.for(dfc_id)
    DataFoodConsortium::Connector::SKOSParser.concepts[dfc_id]
  end
end
