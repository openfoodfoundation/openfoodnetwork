# frozen_string_literal: true

module Admin
  class VouchersController < ResourceController
    before_action :load_enterprise

    def new
      @voucher = Voucher.new
    end

    def create
      @voucher = Voucher.new(
        permitted_resource_params.merge(enterprise: @enterprise)
      )

      if @voucher.save
        flash[:success] = I18n.t(:successfully_created, resource: Spree.t(:voucher))
        redirect_to edit_admin_enterprise_path(@enterprise, anchor: :vouchers_panel)
      else
        render_error
      end
    rescue ActiveRecord::SubclassNotFound
      @voucher.errors.add(:type)
      render_error
    rescue ActiveRecord::RecordNotUnique
      # Rails unique validation doesn't work with soft deleted object, so we rescue the database
      # exception  to display a nice message to the user
      @voucher.errors.add(:code, :taken)
      render_error
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
      params.require(:voucher).permit(:code, :amount, :type)
    end
  end
end
