# frozen_string_literal: true

module OrderManagement
  module Reports
    module BulkCoop
      module Renderers
        class HtmlRenderer < ::Reports::Renderers::Base
          def render(context)
            context.instance_variable_set :@renderer, self
            context.render(action: :create, renderer: self)
          end

          delegate :header, to: :report_data

          def data_rows
            report_data.list
          end
        end
      end
    end
  end
end
