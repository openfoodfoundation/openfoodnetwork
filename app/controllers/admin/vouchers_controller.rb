# frozen_string_literal: true

module Admin
  class VouchersController < ResourceController
    before_action :load_enterprise

    def new
      @voucher = Voucher.new
    end

    def create
      @voucher = Voucher.create(permitted_resource_params.merge(enterprise: @enterprise))

      if @voucher.save
        flash[:success] = flash_message_for(@voucher, :successfully_created)
        redirect_to edit_admin_enterprise_path(@enterprise, anchor: :vouchers_panel)
      else
        flash[:error] = @voucher.errors.full_messages.to_sentence
        render :new
      end
    end

    private

    def load_enterprise
      @enterprise = OpenFoodNetwork::Permissions
        .new(spree_current_user)
        .editable_enterprises
        .find_by(permalink: params[:enterprise_id])
    end

    def permitted_resource_params
      params.require(:voucher).permit(:code, :amount, :voucher_type)
    end
  end
end
