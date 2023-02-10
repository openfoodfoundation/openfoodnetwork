# frozen_string_literal: true

# To be included in api controllers for handeling query params
module ExtraFields
  extend ActiveSupport::Concern

  def invalid_query_param(name, status, msg)
    render status: status, json: json_api_error(msg, error_options:
      {
        title: I18n.t("api.query_param.error.title"),
        source: { parameter: name },
        status: status,
        code: Rack::Utils::SYMBOL_TO_STATUS_CODE[status]
      })
  end

  def extra_fields(type, available_fields)
    fields = params.dig(:extra_fields, type)&.split(',')&.compact&.map(&:to_sym)
    return [] if fields.blank?

    unknown_fields = fields - available_fields

    if unknown_fields.present?
      invalid_query_param(
        "extra_fields[#{type}]", :unprocessable_entity,
        I18n.t("api.query_param.error.extra_fields", fields: unknown_fields.join(', '))
      )
    end

    fields
  end
end
