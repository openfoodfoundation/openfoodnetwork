# frozen_string_literal: true

class VerticalEllipsisMenuComponent < ViewComponent::Base
  attr_reader :id

  def initialize(id: "blerh") #todo: add id for variant rows too
    @id = id
  end
end
