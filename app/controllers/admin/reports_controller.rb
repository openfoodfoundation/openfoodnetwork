# frozen_string_literal: true

module Admin
  class ReportsController < Spree::Admin::BaseController
    include ReportsActions
    helper ReportsHelper

    before_action :authorize_report

    def show
      render_report && return if ransack_params.blank?

      @report = report_class.new(spree_current_user, ransack_params, report_options)

      if export_spreadsheet?
        export_report
      else
        render_report
      end
    end

    private

    def export_report
      render report_format.to_sym => @report.public_send("to_#{report_format}"),
             :filename => report_filename
    end

    def render_report
      assign_view_data
      load_form_options

      render report_type
    end

    def assign_view_data
      @report_type = report_type
      @report_subtype = report_subtype || report_loader.default_report_subtype
      @report_subtypes = report_class.report_subtypes.map do |subtype|
        [t("packing.#{subtype}_report", scope: i18n_scope), subtype]
      end
    end

    def load_form_options
      return unless form_options_required?

      form_options = Reporting::FrontendData.new(spree_current_user)

      @distributors = form_options.distributors.to_a
      @suppliers = form_options.suppliers.to_a
      @order_cycles = form_options.order_cycles.to_a
    end
  end
end
