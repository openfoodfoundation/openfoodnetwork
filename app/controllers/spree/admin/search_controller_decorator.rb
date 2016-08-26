Spree::Admin::SearchController.class_eval do
  def known_users
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

  def users_with_customers_ams
    enterprise_ids = spree_current_user.enterprises.map &:id

    customers = Customer.ransack({m: 'or', email_start: params[:q], name_start: params[:q]})
                        .result(distinct: true)
                        .where(enterprise_id: enterprise_ids)

    render json: customers, each_serializer: Api::Admin::CustomerSerializer
  end
  alias_method_chain :users, :customers_ams
end
