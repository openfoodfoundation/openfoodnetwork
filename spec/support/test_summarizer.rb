# frozen_string_literal: true

# A fake summarizer that implements a more handy public API to reach out to its internal state,
# which greatly simplifyies integration testing.
class TestSummarizer < OrderManagement::Subscriptions::Summarizer
  attr_reader :recorded_issues

  def initialize
    @recorded_issues = {}
    super
  end

  def record_issue(_type, order, message = nil)
    @recorded_issues[order.id] = message
  end
end
