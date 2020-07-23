# frozen_string_literal: true

# Serializer used to render the DFC Person from an OFN User
# into JSON-LD format based on DFC ontology
module DfcProvider
  class PersonSerializer
    def initialize(user)
      @user = user
    end

    def serialized_data
      {
        "@id" => "/personId/#{@user.id}",
        "@type" => "dfc:Person",
        "dfc:familyName" => @user.login,
        "dfc:firtsName" => @user.email,
        "dfc:hasAdress" => {
          "@type" => "dfc:Address",
          "dfc:city" => nil,
          "dfc:country" => nil,
          "dfc:postcode" => nil,
          "dfc:street" => nil
        },
        "dfc:affiliates" => affiliates_serialized_data
      }
    end

    private

    def affiliates_serialized_data
      @user.enterprises.map do |enterprise|
        EnterpriseSerializer.new(enterprise).serialized_data
      end
    end
  end
end
