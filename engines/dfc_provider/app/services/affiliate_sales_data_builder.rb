# frozen_string_literal: true

class AffiliateSalesDataBuilder < DfcBuilder
  class << self
    def person(user)
      DataFoodConsortium::Connector::Person.new(
        urls.affiliate_sales_data_url,
        affiliatedOrganizations: enterprises(user.enterprises)
      )
    end

    def enterprises(enterprises)
      AffiliateSalesQuery.data(enterprises).map do |row|
        AffiliateSalesDataRowBuilder.new(row).build_supplier
      end
    end
  end
end
