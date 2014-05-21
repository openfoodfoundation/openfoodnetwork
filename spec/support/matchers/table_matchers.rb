RSpec::Matchers.define :have_table_row do |row|

  match_for_should do |node|
    @row = row

    false_on_timeout_error do
      wait_until { rows_under(node).include? row }
    end
  end

  match_for_should_not do |node|
    @row = row

    false_on_timeout_error do
      # Without this sleep, we trigger capybara's wait when looking up the table, for the full
      # period of default_wait_time.
      sleep 0.1
      wait_until { !rows_under(node).include? row }
    end
  end

  def rows_under(node)
    node.all('tr').map { |tr| tr.all('th, td').map(&:text) }
  end

  def false_on_timeout_error
    yield
  rescue TimeoutError
    false
  else
    true
  end


  failure_message_for_should do |text|
    "expected to find table row #{@row}"
  end

  failure_message_for_should_not do |text|
    "expected not to find table row #{@row}"
  end

end
