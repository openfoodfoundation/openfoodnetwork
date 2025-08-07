# frozen_string_literal: true

# Authorised user or client using the API
class ApiUser
  CLIENT_MAP = {
    "https://waterlooregionfood.ca/portal/profile" => "cqcm-dev",
  }.freeze

  def self.from_client_id(client_id)
    id = CLIENT_MAP[client_id]

    new(id) if id
  end

  attr_reader :id

  def initialize(id)
    @id = id
  end

  def enterprises
    Enterprise.none
  end
end
