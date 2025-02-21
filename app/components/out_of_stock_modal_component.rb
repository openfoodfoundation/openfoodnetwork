# frozen_string_literal: true

class OutOfStockModalComponent < ModalComponent
  def initialize(id:, variants: [], redirect: false)
    super(id:, modal_class: "medium", instant: true)

    @variants = variants
    @redirect = redirect
  end
end
