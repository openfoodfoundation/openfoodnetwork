Spree::Admin::VariantsController.class_eval do
  helper 'spree/products'


  protected

  def create_before
    option_values = params[:new_variant]
    option_values.andand.each_value {|id| @object.option_values << OptionValue.find(id)}
    @object.save
  end

end
