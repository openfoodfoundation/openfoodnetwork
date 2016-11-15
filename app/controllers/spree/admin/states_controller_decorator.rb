Spree::Admin::StatesController.class_eval do

  def index
    respond_with(@collection) do |format|
      format.html
      format.js { render :partial => 'state_list' }

    Spree::Config.set(params[:state_display])
    end
  end

end