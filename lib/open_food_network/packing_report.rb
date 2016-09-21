module OpenFoodNetwork
  class PackingReport
    attr_reader :params
    def initialize(user, params = {})
      @params = params
      @user = user
    end

    def header
      if is_by_customer?
        ["Hub", "Code", "First Name", "Last Name", "Supplier", "Product", "Variant", "Quantity", "TempControlled?"]
      else
        ["Hub", "Supplier", "Code", "First Name", "Last Name", "Product", "Variant", "Quantity", "TempControlled?"]
      end
    end

    def search
      permissions.visible_orders.complete.not_state(:canceled).search(params[:q])
    end

    def table_items
      orders = search.result

      line_items = permissions.visible_line_items.merge(Spree::LineItem.where(order_id: orders))
      line_items = line_items.supplied_by_any(params[:supplier_id_in]) if params[:supplier_id_in].present?

      line_items_with_hidden_details =
        permissions.editable_line_items.empty? ? line_items : line_items.where('"spree_line_items"."id" NOT IN (?)', permissions.editable_line_items)

      line_items.select{ |li| line_items_with_hidden_details.include? li }.each do |line_item|
        # TODO We should really be hiding customer code here too, but until we
        # have an actual association between order and customer, it's a bit tricky
        line_item.order.bill_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.ship_address.andand.assign_attributes(firstname: "HIDDEN", lastname: "", phone: "", address1: "", address2: "", city: "", zipcode: "", state: nil)
        line_item.order.assign_attributes(email: "HIDDEN")
      end
      line_items
    end

    def rules
      if is_by_customer?
#        customer_rows orders
#        table_items = @line_items

        [
          { group_by: proc { |line_item| line_item.order.distributor },
          sort_by: proc { |distributor| distributor.name } },
          { group_by: proc { |line_item| line_item.order },
          sort_by: proc { |order| order.bill_address.lastname },
          summary_columns: [ proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| "" },
            proc { |line_items| "TOTAL ITEMS" },
            proc { |line_items| "" },
            proc { |line_items| line_items.sum { |li| li.quantity } },
            proc { |line_items| "" } ] },
          { group_by: proc { |line_item| line_item.product.supplier },
            sort_by: proc { |supplier| supplier.name } },
          { group_by: proc { |line_item| line_item.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |line_item| line_item.full_name },
            sort_by: proc { |full_name| full_name } } ]
      else
#        supplier_rows orders
#        table_items = supplier_rows orders
#
        [ { group_by: proc { |line_item| line_item.order.distributor },
          sort_by: proc { |distributor| distributor.name } },
          { group_by: proc { |line_item| line_item.product.supplier },
            sort_by: proc { |supplier| supplier.name },
            summary_columns: [ proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| "" },
              proc { |line_items| "TOTAL ITEMS" },
              proc { |line_items| "" },
              proc { |line_items| line_items.sum { |li| li.quantity } },
              proc { |line_items| "" } ] },
          { group_by: proc { |line_item| line_item.product },
          sort_by: proc { |product| product.name } },
          { group_by: proc { |line_item| line_item.full_name },
          sort_by: proc { |full_name| full_name } },
          { group_by: proc { |line_item| line_item.order },
          sort_by: proc { |order| order.bill_address.lastname } } ]
      end
    end

    def columns
      if is_by_customer?
        [ proc { |line_items| line_items.first.order.distributor.name },
          proc { |line_items| customer_code(line_items.first.order.email) },
          proc { |line_items| line_items.first.order.bill_address.firstname },
          proc { |line_items| line_items.first.order.bill_address.lastname },
          proc { |line_items| line_items.first.product.supplier.name },
          proc { |line_items| line_items.first.product.name },
          proc { |line_items| line_items.first.full_name },
          proc { |line_items| line_items.sum { |li| li.quantity } },
          proc { |line_items| is_temperature_controlled?(line_items.first) }
        ]
      else
        [
          proc { |line_items| line_items.first.order.distributor.name },
          proc { |line_items| line_items.first.product.supplier.name },
          proc { |line_items| customer_code(line_items.first.order.email) },
          proc { |line_items| line_items.first.order.bill_address.firstname },
          proc { |line_items| line_items.first.order.bill_address.lastname },
          proc { |line_items| line_items.first.product.name },
          proc { |line_items| line_items.first.full_name },
          proc { |line_items| line_items.sum { |li| li.quantity } },
          proc { |line_items| is_temperature_controlled?(line_items.first) }
        ]
      end
    end

    private

    def permissions
      return @permissions unless @permissions.nil?
      @permissions = OpenFoodNetwork::Permissions.new(@user)
    end

    def is_temperature_controlled?(line_item)
      if line_item.product.shipping_category.andand.temperature_controlled
        "Yes"
      else
        "No"
      end
    end

    def is_by_customer?
      params[:report_type] == "pack_by_customer"
    end

    def customer_code(email)
      customer = Customer.where(email: email).first
      customer.nil? ? "" : customer.code
    end
  end
end
