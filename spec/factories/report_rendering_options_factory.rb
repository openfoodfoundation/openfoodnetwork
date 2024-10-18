# frozen_string_literal: true

FactoryBot.define do
  factory :orders_and_distributors_options, class: ReportRenderingOptions do
    report_type { "orders_and_distributors" }
  end
end
