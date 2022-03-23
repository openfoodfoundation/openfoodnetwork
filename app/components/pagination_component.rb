# frozen_string_literal: true

class PaginationComponent < ViewComponentReflex::Component
  def initialize(pagy:, data:)
    super
    @count = pagy.count
    @page = pagy.page
    @per_page = pagy.items
    @pages = pagy.pages
    @next = pagy.next
    @prev = pagy.prev
    @data = data
    @series = pagy.series
  end
end
