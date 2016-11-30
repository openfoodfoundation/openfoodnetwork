angular.module("admin.orders").directive 'customerSearchOverride', ->
  restrict: 'C'
  scope:
    distributorId: '@'
  link: (scope, element, attr) ->
    formatCustomerResult = (customer) ->
      customerTemplate
        customer: customer
        bill_address: customer.bill_address
        ship_address: customer.ship_address

    element.select2
      placeholder: Spree.translations.choose_a_customer
      minimumInputLength: 3
      ajax:
        url: '/admin/search/customers.json'
        datatype: 'json'
        data: (term, page) ->
          {
            q: term
            distributor_id: scope.distributorId  # modified
          }
        results: (data, page) ->
          { results: data }
      dropdownCssClass: 'customer_search'
      formatResult: formatCustomerResult
      formatSelection: (customer) ->
        _.each [
          'bill_address'
          'ship_address'
        ], (address) ->
          data = customer[address]
          address_parts = [
            'firstname'
            'lastname'
            'company'
            'address1'
            'address2'
            'city'
            'zipcode'
            'phone'
          ]
          attribute_wrapper = '#order_' + address + '_attributes_'
          if data  # modified
            _.each address_parts, (part) ->
              $(attribute_wrapper + part).val data[part]
              return
            $(attribute_wrapper + 'state_id').select2 'val', data['state_id']
            $(attribute_wrapper + 'country_id').select2 'val', data['country_id']
          else
            _.each address_parts, (part) ->
              $(attribute_wrapper + part).val ''
              return
            $(attribute_wrapper + 'state_id').select2 'val', ''
            $(attribute_wrapper + 'country_id').select2 'val', ''
          return
        $('#order_email').val customer.email
        $('#user_id').val customer.user_id  # modified
        $('#guest_checkout_true').prop 'checked', false
        $('#guest_checkout_false').prop 'checked', true
        $('#guest_checkout_false').prop 'disabled', false
        customer.email
