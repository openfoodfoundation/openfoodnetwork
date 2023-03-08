class OrderInvoiceComparator
  def equal?(invoice1, invoice2)
    # We'll use a recursive BFS algorithm to find if current state of invoice is outdated
    # the root will be the order
    # On each node, we'll a list of relevant attributes that will be used on the comparison
    bfs(invoice1.presenter, invoice2.presenter)
  end

  def bfs(node1, node2)
    simple_values1, presenters1 = group_relevant_values(node1)
    simple_values2, presenters2 = group_relevant_values(node2)
    return false if simple_values1 != simple_values2

    return false if presenters1.size != presenters2.size

    presenters1.zip(presenters2).each do |presenter1, presenter2|
      return false unless bfs(presenter1, presenter2)
    end
    true
  end

  def group_relevant_values(node)
    return [[], []] unless node.respond_to?(:relevant_values)

    grouped = node.relevant_values.group_by(&grouper)
    [grouped[:simple] || [], grouped[:presenters]&.flatten || []]
  end

  def grouper
    proc do |value|
      if value.is_a?(Array) || value.class.to_s.starts_with?("Invoice::DataPresenter")
        :presenters
      else
        :simple
      end
    end
  end
end
