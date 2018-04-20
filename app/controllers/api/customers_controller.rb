module Api
  class CustomersController < Spree::Api::BaseController
    respond_to :json

    def update
      @customer = Customer.find(params[:id])
      authorize! :update, @customer

      if @customer.update_attributes(params[:customer])
        render text: @customer.id, :status => 200
      else
        invalid_resource!(@customer)
      end
    end
  end
end
