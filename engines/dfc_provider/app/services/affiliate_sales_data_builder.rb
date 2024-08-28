# frozen_string_literal: true

class AffiliateSalesDataBuilder < DfcBuilder
  class << self
    def person
      DataFoodConsortium::Connector::Person.new(
        urls.affiliate_sales_data_url,
      )
    end
  end
end
