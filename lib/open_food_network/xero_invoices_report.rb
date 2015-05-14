module OpenFoodNetwork
  class XeroInvoicesReport
    def initialize(orders, opts={})
      @orders = orders
      @opts = opts.reverse_merge({invoice_date: Date.today,
                                  due_date: 2.weeks.from_now.to_date,
                                  account_code: 'food sales'})
    end

    def header
      %w(*ContactName EmailAddress POAddressLine1 POAddressLine2 POAddressLine3 POAddressLine4 POCity PORegion POPostalCode POCountry *InvoiceNumber Reference *InvoiceDate *DueDate InventoryItemCode *Description *Quantity *UnitAmount Discount *AccountCode *TaxType TrackingName1 TrackingOption1 TrackingName2 TrackingOption2 Currency BrandingTheme)
    end

    def table
      rows = []

      @orders.each_with_index do |order, i|
        invoice_number = invoice_number_for(order, i)
        rows << summary_row(order, 'Total untaxable produce (no tax)',       0, invoice_number, 'GST Free Income', @opts)
        rows << summary_row(order, 'Total taxable produce (tax inclusive)',  0, invoice_number, 'GST on Income', @opts)
        rows << summary_row(order, 'Total untaxable fees (no tax)',          0, invoice_number, 'GST Free Income', @opts)
        rows << summary_row(order, 'Total taxable fees (tax inclusive)',     0, invoice_number, 'GST on Income', @opts)
        rows << summary_row(order, 'Delivery Shipping Cost (tax inclusive)', 0, invoice_number, 'Tax or No Tax - depending on enterprise setting', @opts)
      end

      rows
    end


    private

    def invoice_number_for(order, i)
      @opts[:initial_invoice_number] ? @opts[:initial_invoice_number].to_i+i : order.number
    end

    def summary_row(order, description, amount, invoice_number, tax_type, opts={})
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
       invoice_number,
       order.number,
       opts[:invoice_date],
       opts[:due_date],
       '',
       description,
       '1',
       amount,
       '',
       opts[:account_code],
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
