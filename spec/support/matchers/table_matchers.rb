RSpec::Matchers.define :have_table_row do |row|

  match do |node|
    @row = row

    node.has_selector? "tr", text: row.join(" ").strip # Check for appearance
    rows_under(node).include? row # Robust check of columns
  end

  match_when_negated do |node|
    @row = row

    node.has_no_selector? "tr", text: row.join(" ").strip # Check for appearance
    !rows_under(node).include? row # Robust check of columns
  end

  failure_message do |text|
    "expected to find table row #{@row}"
  end

  failure_message_when_negated do |text|
    "expected not to find table row #{@row}"
  end

  def rows_under(node)
    node.all('tr').map { |tr| tr.all('th, td').map(&:text) }
  end
end



# find("#my-table").should match_table [[...]]
RSpec::Matchers.define :match_table do |expected_table|

  match do |node|
    rows = node.
      all("tr").
      map { |r| r.all("th,td").map { |c| c.text.strip } }

    if rows.count != expected_table.count
      @failure_message = "found table with #{rows.count} rows, expected #{expected_table.count}"

    else
      rows.each_with_index do |row, i|
        expected_row = expected_table[i]
        if row.count != expected_row.count
          @failure_message = "row #{i} has #{row.count} columns, expected #{expected_row.count}"
          break

        elsif row != expected_row
          row.each_with_index do |cell, j|
            if cell != expected_row[j]
              @failure_message = "cell [#{i}, #{j}] has content '#{cell}', expected '#{expected_row[j]}'"
              break
            end
          end
          break if @failure_message
        end
      end
    end

    @failure_message.nil?
  end

  failure_message do |text|
    @failure_message
  end

end
