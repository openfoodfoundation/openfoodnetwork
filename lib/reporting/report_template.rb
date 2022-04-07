# frozen_string_literal: true

module Reporting
  class ReportTemplate
    include ReportsHelper
    attr_accessor :user, :params, :ransack_params

    delegate :as_json, :as_arrays, :to_csv, :to_xlsx, :to_ods, :to_pdf, :to_json, to: :renderer
    delegate :formatted_rules, :header_option?, :summary_row_option?, to: :ruler
    delegate :grouped_data, :rows, to: :grouper

    def initialize(user, params = {})
      @user = user
      @params = params
      @params = @params.permit!.to_h unless @params.is_a? Hash
      @ransack_params = @params[:q] || {}
    end

    # Message to be displayed at the top of rendered table
    def message
      ""
    end

    # Ransack search to get base ActiveRelation
    # If the report object do not use ransack search, create a fake one just for the form_for
    # in reports/show.haml
    def search
      Ransack::Search.new(Spree::Order)
    end

    # Can be re implemented in subclasses if they not use yet the new syntax
    # with columns method
    def table_headers
      columns.keys.filter{ |key| !key.in?(fields_to_hide) }.map do |key|
        custom_headers[key] || I18n.t("report_header_#{key}")
      end
    end

    def translate_header(key)
      # Quite some headers use currency interpolation, so providing it by default
      default_params = { currency: currency_symbol, currency_symbol: currency_symbol }
      custom_headers[key] || I18n.t("report_header_#{key}", **default_params)
    end

    # Headers are automatically translated with table_headers method
    # You can customize some header name if needed
    def custom_headers
      {}
    end

    def table_rows
      raise NotImplementedError
    end

    def fields_to_hide
      if params[:display_header_row]
        formatted_rules.map { |rule| rule[:fields_used_in_header] }.flatten.reject(&:blank?)
      else
        []
      end
    end

    # Rules for grouping, ordering, and summary rows
    # Rule Full Example. In the following item reference the query_result item and
    #                    row the transformation of this item into the expected result
    # {
    #   group_by: proc { |item, row| row.last_name },
    #   group_by: :last_name, # same that previous line,
    #   group_by: proc { |line_item, row| line_item.product },
    #   sort_by: proc { |product| product.name },
    #   header: proc { |group_key, items, rows| items.first.display_name },
    #   header: true, # shortcut to use group_key as header
    #   header: :supplier, # shortcut to use supplier column as header
    #   header: [:last_name, :first_name], # shortcut to use last_name & first_name as header
    #   header_class: "h1 h2 h3 h4 text-center background", # class applies to the header row
    #   # Those fields will be hidden when the header_row is activated
    #   fields_used_in_header: [:first_name, :last_name],
    #   summary_row: proc do |group_key, items, rows|
    #     {
    #       quantity: rows.sum(&:quantity),
    #       price: "#{rows.sum(&:price)} #{currency_symbol}"
    #     }
    #   end,
    #   summary_row_class: "", # by default 'text-bold'
    #   summary_row_label: "Total by Customer" # by default 'TOTAL'
    #   summary_row_label: proc { |group_key, items, rows| "Total for #{group_key}" }
    # }
    def rules
      []
    end

    private

    def raw_render?
      params[:report_format].in?(['json', 'csv'])
    end

    def renderer
      @renderer ||= ReportRenderer.new(self)
    end

    def grouper
      @grouper ||= ReportGrouper.new(self)
    end

    def ruler
      @ruler ||= ReportRuler.new(self)
    end
  end
end
