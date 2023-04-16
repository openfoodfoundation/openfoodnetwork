class Invoice::DataPresenter::Variant < Invoice::DataPresenter::Base
  attributes :id, :display_name, :options_text
  attributes_with_presenter :product

  def name_to_display
    return product.name if display_name.blank?

    display_name
  end
end