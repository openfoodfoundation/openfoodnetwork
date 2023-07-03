# frozen_string_literal: true

module Admin
  class VouchersController < ResourceController
    before_action :load_enterprise

    def new
      @voucher = Voucher.new
    end

    def create
      case params[:vouchers_flat_rate][:voucher_type]
      when "Vouchers::FlatRate"
        @voucher =
          Vouchers::FlatRate.create(permitted_resource_params.merge(enterprise: @enterprise))
      when "Vouchers::PercentageRate"
        @voucher =
          Vouchers::PercentageRate.create(permitted_resource_params.merge(enterprise: @enterprise))
      else
        @voucher.errors.add(:type)
        return render_error
      end

      if @voucher.save
        flash[:success] = I18n.t(:successfully_created, resource: "Voucher")
        redirect_to edit_admin_enterprise_path(@enterprise, anchor: :vouchers_panel)
      else
        render_error
      end
    end

    private

    def render_error
      flash[:error] = @voucher.errors.full_messages.to_sentence
      render :new
    end

    def load_enterprise
      @enterprise = OpenFoodNetwork::Permissions
        .new(spree_current_user)
        .editable_enterprises
        .find_by(permalink: params[:enterprise_id])
    end

    def permitted_resource_params
      params.require(:vouchers_flat_rate).permit(:code, :amount)
    end
  end
end
