# frozen_string_literal: true

# One row per API request, written by ApiLogger.
#
# There is deliberately no UI for this data: reports are built in Metabase,
# which reads the table directly.
class ApiLog < ApplicationRecord
  belongs_to :user, class_name: "Spree::User", optional: true
end
