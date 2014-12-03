RSpec::Matchers.define :have_select2 do |id, options={}|

  # TODO: Implement other have_select options
  #       http://www.rubydoc.info/github/jnicklas/capybara/Capybara/Node/Matchers#has_select%3F-instance_method
  # TODO: Instead of passing in id, use a more general locator

  match_for_should do |node|
    @id, @options, @node = id, options, node

    #id = find_label_by_text(locator)
    from = "#s2id_#{id}"

    results = []

    results << node.has_selector?(from)

    if results.all?
      results << all_options_present(from, options[:with_options]) if options.key? :with_options
      results << exact_options_present(from, options[:options]) if options.key? :options
    end

    results.all?
  end

  failure_message_for_should do |actual|
    message =  "expected to find select2 ##{@id}"
    message += " with #{@options.inspect}" if @options.any?
    message
  end

  match_for_should_not do |node|
    raise "Not yet implemented"
  end


  def all_options_present(from, options)
    with_select2_open(from) do
      options.all? do |option|
        @node.has_selector? "div.select2-drop-active ul.select2-results li", text: option
      end
    end
  end

  def exact_options_present(from, options)
    with_select2_open(from) do
      @node.all("div.select2-drop-active ul.select2-results li").map(&:text) == options
    end
  end

  def with_select2_open(from)
    find(from).click
    r = yield
    find(from).click
    r
  end
end
