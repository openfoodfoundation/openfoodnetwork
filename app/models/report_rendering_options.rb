# frozen_string_literal: true

class ReportRenderingOptions < ApplicationRecord
  belongs_to :user, class_name: "Spree::User"
  serialize :options, Hash
end
