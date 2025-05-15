# frozen_string_literal: true

module DfcProvider
  class PlatformsController < DfcProvider::ApplicationController
    before_action :check_enterprise

    def index
      render json: <<~JSON
        {"@context":"https://cdn.startinblox.com/owl/context-bis.jsonld","@id":"https://mydataserver.com/enterprises/1/platforms","dfc-t:platforms":{"@list":[{"@id":"https://waterlooregionfood.ca/portal/profile","@type":"dfc-t:Platform","_id":{"$oid":"682afcc4966dbb3aa7464d56"},"description":"A super duper portal for the waterloo region","dfc-t:hasAssignedScopes":{"@list":[{"@id":"https://data-server.cqcm.startinblox.com/enterprises/1/platforms/scopes/ReadEnterprise","@type":"dfc-t:Scope","dfc-t:scope":"ReadEnterprise"},{"@id":"https://data-server.cqcm.startinblox.com/enterprises/1/platforms/scopes/WriteEnterprise","@type":"dfc-t:Scope","dfc-t:scope":"WriteEnterprise"},{"@id":"https://data-server.cqcm.startinblox.com/enterprises/1/platforms/scopes/ReadProducts","@type":"dfc-t:Scope","dfc-t:scope":"ReadProducts"},{"@id":"https://data-server.cqcm.startinblox.com/enterprises/1/platforms/scopes/WriteProducts","@type":"dfc-t:Scope","dfc-t:scope":"WriteProducts"},{"@id":"https://data-server.cqcm.startinblox.com/enterprises/1/platforms/scopes/ReadOrders","@type":"dfc-t:Scope","dfc-t:scope":"ReadOrders"},{"@id":"https://data-server.cqcm.startinblox.com/enterprises/1/platforms/scopes/WriteOrders","@type":"dfc-t:Scope","dfc-t:scope":"WriteOrders"}],"@type":"rdf:List"},"termsandconditions":"https://waterlooregionfood.ca/terms-and-conditions","title":"Waterloo Region Food Portal"},{"@id":"https://anotherplatform.ca/portal/profile","@type":"dfc-t:Platform","_id":{"$oid":"682b2e2b031c28f69cda1645"},"description":"A super duper portal for the waterloo region","dfc-t:hasAssignedScopes":{"@list":[],"@type":"rdf:List"},"termsandconditions":"https://anotherplatform.ca/terms-and-conditions","title":"anotherplatform Portal"}],"@type":"rdf:List"}}
      JSON
    end
  end
end
