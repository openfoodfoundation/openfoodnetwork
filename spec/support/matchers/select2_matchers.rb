RSpec::Matchers.define :have_select2 do |id, options={}|

  # TODO: Implement other have_select options
  #       http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Node/Matchers#has_select%3F-instance_method
  # TODO: Instead of passing in id, use a more general locator

  match_for_should do |node|
    @id, @options = id, options

    #id = find_label_by_text(locator)
    from = "#s2id_#{id}"

    found_element = node.has_selector? from

    if !found_element
      false

    else
      if options.key? :with_options
        find(from).click

        all_options_present = options[:with_options].all? do |option|
          node.has_selector? "div.select2-drop-active ul.select2-results li", text: option
        end

        find(from).click

        all_options_present
      end
    end
  end

  failure_message_for_should do |actual|
    message =  "expected to find select2 ##{@id}"
    message += " with #{@options.inspect}" if @options.any?
    message
  end

  match_for_should_not do |node|
    raise "Not yet implemented"
  end
end
