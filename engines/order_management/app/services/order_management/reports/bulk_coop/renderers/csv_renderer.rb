# frozen_string_literal: true

module OrderManagement
  module Reports
    module BulkCoop
      module Renderers
        class CsvRenderer < ::Reports::Renderers::Base
          def render(context)
            context.send_data(generate, filename: filename)
          end

          def generate
            CSV.generate do |csv|
              csv << report_data.header

              report_data.list.each do |data|
                csv << data
              end
            end
          end

          private

          def filename
            timestamp = Time.zone.now.strftime("%Y%m%d")
            "#{report_data.parameters[:report_type]}_#{timestamp}.csv"
          end
        end
      end
    end
  end
end
