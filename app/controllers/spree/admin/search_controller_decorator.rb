Spree::Admin::SearchController.class_eval do
  def known_users
    binding.pry
    if exact_match = Spree.user_class.find_by_email(params[:q])
      @users = [exact_match]
    else
      @users = spree_current_user.known_users.ransack({
        :m => 'or',
        :email_start => params[:q],
        :ship_address_firstname_start => params[:q],
        :ship_address_lastname_start => params[:q],
        :bill_address_firstname_start => params[:q],
        :bill_address_lastname_start => params[:q]
        }).result.limit(10)
    end
    render :users

  end
end
