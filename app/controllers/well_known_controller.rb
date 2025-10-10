# frozen_string_literal: true

class WellKnownController < ApplicationController
  layout nil

  def dfc
    base = "https://github.com/datafoodconsortium/taxonomies/releases/latest/download/scopes.rdf#"
    render json: {
      "#{base}ReadEnterprise" => "/api/dfc/enterprises/",
      "#{base}ReadProducts" => "/api/dfc/supplied_products/",
    }
  end
end
