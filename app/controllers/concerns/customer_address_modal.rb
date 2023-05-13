# frozen_string_literal: true

module CustomerAddressModal
  CABLE_FRAME_SELECTOR = "#cable-frame"
  STIMULUS_WAIT = 200

  def show
    load_customer_and_address
    show_address_modal
  end

  def update
    load_customer_and_address
    if @customer.update(customer_params)
      hide_address_modal
    else
      show_address_modal
    end
  end

  private

  def address_link_selector
    "#customer-#{@customer.id}-#{address_type.to_s.gsub('_', '-')}-link"
  end

  def customer_params
    params.require(:customer).permit(
      ship_address_attributes: PermittedAttributes::Address.attributes,
      bill_address_attributes: PermittedAttributes::Address.attributes
    )
  end

  def hide_address_modal
    render cable_ready: cable_car.inner_html(
      CABLE_FRAME_SELECTOR,
      partial(
        "admin/shared/cable_success_message",
        formats: [:html],
        locals: { message: I18n.t("admin.customers.index.update_address_success") }
      )
    ).inner_html(
      address_link_selector,
      html: @customer.public_send(address_type).address1
    )
  end

  def load_customer_and_address
    @customer = Customer.find(params[:customer_id])
    @address = @customer.public_send(address_type) || @customer.public_send("build_#{address_type}")
  end

  def model_class
    Customer
  end

  def show_address_modal
    render cable_ready: cable_car.inner_html(
      CABLE_FRAME_SELECTOR,
      partial("admin/customers/address_modal", formats: [:html])
    ).dispatch_event(name: "modal:open", delay: STIMULUS_WAIT)
  end
end
