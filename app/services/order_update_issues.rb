# Wrapper for a hash of issues encountered by instances of OrderSyncer and LineItemSyncer
# Used to report issues to the user when they attempt to update a standing order

class OrderUpdateIssues
  def initialize
    @issues = {}
  end

  delegate :[], :keys, to: :issues

  def add(order, issue)
    @issues[order.id] ||= []
    @issues[order.id] << issue
  end

  private

  attr_reader :issues
end
