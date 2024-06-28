# frozen_string_literal: true

module Admin
  class ReportsController < Spree::Admin::BaseController
    include ActiveStorage::SetCurrent
    include ReportsActions
    helper ReportsHelper

    before_action :authorize_report, only: [:show]

    # Define model class for Can? permissions
    def model_class
      Admin::ReportsController
    end

    def index
      @reports = reports.select do |report_type, _description|
        can? report_type, :report
      end
    end

    def show
      @report = report_class.new(spree_current_user, params, render: render_data?)
      @rendering_options = rendering_options # also stores user preferences

      if render_data?
        render_in_background
      else
        show_report
      end
    end

    private

    def show_report
      assign_view_data
      render "show"
    end

    def assign_view_data
      @report_type = report_type
      @report_subtypes = report_subtypes
      @report_subtype = report_subtype
      @report_title = report_title
      @data = Reporting::FrontendData.new(spree_current_user)

      variant_id_in = params[:variant_id_in]&.compact_blank
      load_selected_variant if variant_id_in.present?
    end

    # Orders and Fulfillment Reports include a per product filter, load any selected product
    def load_selected_variant
      variant = Spree::Variant.find(params[:variant_id_in][0])
      @variant_serialized = Api::Admin::VariantSerializer.new(variant)
    end

    def render_data?
      request.post?
    end

    def render_in_background
      cable_ready[ScopedChannel.for_id(params[:uuid])]
        .inner_html(
          selector: "#report-go",
          html: helpers.button(t(:go), "report__submit-btn", "submit", disabled: true)
        ).inner_html(
          selector: "#report-table",
          html: render_to_string(partial: "admin/reports/loading")
        ).scroll_into_view(
          selector: "#report-table",
          block: "start"
        ).broadcast

      ReportJob.perform_later(
        report_class:, user: spree_current_user, params:,
        format: report_format,
        filename: report_filename,
        channel: ScopedChannel.for_id(params[:uuid]),
      )

      head :no_content
    end
  end
end
