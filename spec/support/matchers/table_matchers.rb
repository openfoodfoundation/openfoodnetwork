RSpec::Matchers.define :have_table_row do |row|

  match_for_should do |node|
    @row = row

    node.has_selector? "tr", text: row.join(" ").strip # Check for appearance
    rows_under(node).include? row # Robust check of columns
  end

  match_for_should_not do |node|
    @row = row

    node.has_no_selector? "tr", text: row.join(" ").strip # Check for appearance
    !rows_under(node).include? row # Robust check of columns
  end

  failure_message_for_should do |text|
    "expected to find table row #{@row}"
  end

  failure_message_for_should_not do |text|
    "expected not to find table row #{@row}"
  end

  def rows_under(node)
    node.all('tr').map { |tr| tr.all('th, td').map(&:text) }
  end
end
