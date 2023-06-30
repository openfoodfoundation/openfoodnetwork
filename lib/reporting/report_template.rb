# frozen_string_literal: true

module Reporting
  class ReportTemplate
    include ReportsHelper
    attr_accessor :user, :params, :ransack_params

    delegate :render_as, :as_json, :to_html, :to_csv, :to_xlsx, :to_pdf, :to_json, to: :renderer
    delegate :unformatted_render?, :html_render?, :display_header_row?, :display_summary_row?,
             to: :renderer

    delegate :rows, :table_rows, :grouped_data, to: :rows_builder
    delegate :available_headers, :table_headers, :fields_to_hide, :fields_to_show,
             to: :headers_builder

    delegate :formatted_rules, :header_option?, :summary_row_option?, to: :ruler

    def initialize(user, params = {}, render: false)
      unless render
        params.reverse_merge!(default_params)
        params[:q] ||= {}
        params[:q].reverse_merge!(default_params[:q]) if default_params[:q].present?
      end
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

    # The search result, usually an ActiveRecord Array
    def query_result
      raise NotImplementedError
    end

    # Convert the query_result into expected row result (which will be displayed)
    # Example
    # {
    #   name: proc { |model| model.display_name },
    #   best_friend: proc { |model| model.friends.first.first_name }
    # }
    def columns
      raise NotImplementedError
    end

    # Exple { total_price: :currency }
    def columns_format
      {}
    end

    # Headers are automatically translated with table_headers method
    # You can customize some header name if needed
    def custom_headers
      {}
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

    # Default filters/search params to be used
    def default_params
      {}
    end

    def skip_duplicate_rows?
      false
    end

    private

    def renderer
      @renderer ||= ReportRenderer.new(self)
    end

    def rows_builder
      @rows_builder ||= ReportRowsBuilder.new(self, @user)
    end

    def headers_builder
      @headers_builder ||= ReportHeadersBuilder.new(self, @user)
    end

    def ruler
      @ruler ||= ReportRuler.new(self)
    end
  end
end
