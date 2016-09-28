Spree::UsersController.class_eval do
  layout 'darkswarm'

  prepend_before_filter :load_object, :only => [:edit_address, :update_address, :show, :edit, :update]

  def edit_address
    unless @user.ship_address
      @user.ship_address = Spree::Address.new
      @user.ship_address.country = Spree::Country.find_by_id(Spree::Config[:default_country_id])
    end
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
