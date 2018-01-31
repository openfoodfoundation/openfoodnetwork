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
