Spree::UsersController.class_eval do
  layout 'darkswarm'

  prepend_before_filter :load_object, :only => [:edit_address, :update_address, :show, :edit, :update]

  def edit_address
    country_id = Spree::Config[:default_country_id]
    @user.build_ship_address(country_id: country_id) unless @user.ship_address
    @user.build_bill_address(country_id: country_id) unless @user.bill_address

    render :edit_address
  end

  def update_address
    if @user.update_attributes(params[:user])
      redirect_to spree.account_url, :notice => t(:account_updated)
    else
      render :edit_address
    end
  end
end
