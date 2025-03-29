# frozen_string_literal: true

ActiveSupport::Notifications.subscribe(/deprecation/) do |_name, _start, _finish, _id, payload|
  e = ActiveSupport::DeprecationException.new(payload[:message])
  e.set_backtrace(payload[:callstack].map(&:to_s))

  Bugsnag.notify(e) do |report|
    report.severity = "warning"
    report.add_tab(
      :deprecation,
      payload.except(:callstack),
    )
  end
end
