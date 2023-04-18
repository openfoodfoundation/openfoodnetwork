# frozen_string_literal: true

module Admin
  class VouchersController < ResourceController
    before_action :load_enterprise

    def new
      @voucher = Voucher.new
    end

    def create
      voucher_params = permitted_resource_params.merge(enterprise: @enterprise)
      @voucher = Voucher.create(voucher_params)

      if @voucher.save
        redirect_to(
          "#{edit_admin_enterprise_path(@enterprise)}#vouchers_panel",
          flash: { success: flash_message_for(@voucher, :successfully_created) }
        )
      else
        flash[:error] = @voucher.errors.full_messages.to_sentence
        render :new
      end
    end

    private

    def load_enterprise
      @enterprise = Enterprise.find_by(permalink: params[:enterprise_id])
    end

    def permitted_resource_params
      params.require(:voucher).permit(:code, :amount)
    end
  end
end
