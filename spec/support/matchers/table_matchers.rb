RSpec::Matchers.define :have_table_row do |row|

  match do |node|
    @row = row
    node.all('tr').map { |tr| tr.all('th, td').map(&:text) }.include? row
  end

  failure_message_for_should do |text|
    "expected to find table row #{@row}"
  end

  failure_message_for_should_not do |text|
    "expected not to find table row #{@row}"
  end

end
