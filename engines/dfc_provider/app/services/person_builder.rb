# frozen_string_literal: true

class PersonBuilder < DfcBuilder
  def self.person(user)
    DataFoodConsortium::Connector::Person.new(
      urls.person_url(user.id),
      firstName: user.bill_address&.firstname,
      lastName: user.bill_address&.lastname,
      affiliatedOrganizations: enterprises(user),
    )
  end

  def self.enterprises(user)
    user.enterprises.map do |enterprise|
      EnterpriseBuilder.enterprise(enterprise)
    end
  end
end
