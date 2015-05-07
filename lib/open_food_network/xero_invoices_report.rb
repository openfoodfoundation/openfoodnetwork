module OpenFoodNetwork
  class XeroInvoicesReport
    def initialize(orders)
      @orders = orders
    end

    def header
      %w(*ContactName EmailAddress POAddressLine1 POAddressLine2 POAddressLine3 POAddressLine4 POCity PORegion POPostalCode POCountry *InvoiceNumber Reference *InvoiceDate *DueDate InventoryItemCode *Description *Quantity *UnitAmount Discount *AccountCode *TaxType TrackingName1 TrackingOption1 TrackingName2 TrackingOption2 Currency BrandingTheme)
    end

    def table
      rows = []

      @orders.each do |order|
        rows << summary_row(order, 'Total untaxable produce (no tax)',       0, 'GST Free Income')
        rows << summary_row(order, 'Total taxable produce (tax inclusive)',  0, 'GST on Income')
        rows << summary_row(order, 'Total untaxable fees (no tax)',          0, 'GST Free Income')
        rows << summary_row(order, 'Total taxable fees (tax inclusive)',     0, 'GST on Income')
        rows << summary_row(order, 'Delivery Shipping Cost (tax inclusive)', 0, 'Tax or No Tax - depending on enterprise setting')
      end

      rows
    end


    private

    def summary_row(order, description, amount, tax_type)
      [order.bill_address.full_name,
       order.email,
       order.bill_address.address1,
       order.bill_address.address2,
       '',
       '',
       order.bill_address.city,
       order.bill_address.state,
       order.bill_address.zipcode,
       order.bill_address.country.andand.name,
       order.number, # To customise
       order.number,
       Date.today, # To customise
       2.weeks.from_now.to_date, # To customise
       '',
       description,
       '1',
       amount,
       '',
       'food sales', # To customise
       tax_type,
       '',
       '',
       '',
       '',
       Spree::Config.currency,
       ''
      ]
    end

  end
end
