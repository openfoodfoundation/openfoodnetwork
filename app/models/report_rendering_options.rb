# frozen_string_literal: true

class ReportRenderingOptions < ApplicationRecord
  self.belongs_to_required_by_default = false

  belongs_to :user, class_name: "Spree::User"
  serialize :options, Hash
end
