RSpec::Matchers.define :have_select2 do |id, options={}|

  # TODO: Implement other have_select options
  #       http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Node/Matchers#has_select%3F-instance_method
  # TODO: Instead of passing in id, use a more general locator

  match do |node|
    @id, @options, @node = id, options, node

    #id = find_label_by_text(locator)
    from = "#s2id_#{id}"

    results = []

    results << node.has_selector?(from)

    if results.all?
      results << selected_option_is(from, options[:selected]) if options.key? :selected
    end

    if results.all?
      results << all_options_present(from, options[:with_options]) if options.key? :with_options
      results << exact_options_present(from, options[:options]) if options.key? :options
      results << no_options_present(from, options[:without_options]) if options.key? :without_options
    end

    results.all?
  end

  failure_message do |actual|
    message  = "expected to find select2 ##{@id}"
    message += " with #{@options.inspect}" if @options.any?
    message
  end

  match_when_negated do |node|
    @id, @options, @node = id, options, node

    #id = find_label_by_text(locator)
    from = "#s2id_#{id}"

    results = []

    results << node.has_no_selector?(from, wait: 1)

    # if results.all?
    #   results << selected_option_is(from, options[:selected]) if options.key? :selected
    # end

    if results.none?
      results << all_options_absent(from, options[:with_options]) if options.key? :with_options
      #results << exact_options_present(from, options[:options]) if options.key? :options
      #results << no_options_present(from, options[:without_options]) if options.key? :without_options
    end

    if (options.keys & %i(selected options without_options)).any?
      raise "Not yet implemented"
    end

    results.any?
  end

  failure_message_when_negated do |actual|
    message  = "expected not to find select2 ##{@id}"
    message += " with #{@options.inspect}" if @options.any?
    message
  end

  def all_options_present(from, options)
    with_select2_open(from) do
      options.all? do |option|
        @node.has_selector? "div.select2-drop-active ul.select2-results li", text: option
      end
    end
  end

  def all_options_absent(from, options)
    with_select2_open(from) do
      options.all? do |option|
        @node.has_no_selector? "div.select2-drop-active ul.select2-results li", text: option
      end
    end
  end

  def exact_options_present(from, options)
    with_select2_open(from) do
      @node.all("div.select2-drop-active ul.select2-results li").map(&:text) == options
    end
  end

  def no_options_present(from, options)
    with_select2_open(from) do
      options.none? do |option|
        @node.has_selector? "div.select2-drop-active ul.select2-results li", text: option
      end
    end
  end

  def selected_option_is(from, text)
    within find(from) do
      find("a.select2-choice").text == text
    end
  end

  def with_select2_open(from)
    open_select2 from
    r = yield
    close_select2 from
    r
  end
end
