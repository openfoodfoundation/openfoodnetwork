Spree::UsersController.class_eval do
  layout 'darkswarm'

  prepend_before_filter :load_object, :only => [:edit_address]

  def edit_address
    render :edit
  end
end
