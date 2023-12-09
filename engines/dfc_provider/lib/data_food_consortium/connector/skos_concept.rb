# frozen_string_literal: true

# Patch: Improve parsing of SKOS Concept. Will be fixed upstream
require_relative 'skos_helper'

module DataFoodConsortium
  module Connector
    class SKOSConcept
      include DataFoodConsortium::Connector::SKOSHelper
    end
  end
end
