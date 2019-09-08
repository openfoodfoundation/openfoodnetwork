module OpenFoodNetwork
  class OrderGrouper
    def initialize(rules, column_constructors)
      @rules = rules
      @column_constructors = column_constructors
    end

    def build_tree(items, remaining_rules)
      rules = remaining_rules.clone
      if rules.any?
        rule = rules.delete_at(0) # Remove current rule for subsequent groupings
        group_and_sort(rule, rules, items)
      else
        items
      end
    end

    def group_and_sort(rule, remaining_rules, items)
      branch = {}
      groups = items.group_by { |item| rule[:group_by].call(item) }

      sorted_groups = groups.sort_by { |key, _value| rule[:sort_by].call(key) }

      sorted_groups.each do |property, items_by_property|
        branch[property] = build_tree(items_by_property, remaining_rules)

        next if rule[:summary_columns].nil? || is_leaf_node(branch[property])

        branch[property][:summary_row] = {
          items: items_by_property,
          columns: rule[:summary_columns]
        }
      end

      branch
    end

    def build_table(groups)
      rows = []
      if is_leaf_node(groups)
        rows << @column_constructors.map { |column_constructor| column_constructor.call(groups) }
      else
        groups.each do |key, group|
          if key == :summary_row
            rows << group[:columns].map { |cols| cols.call(group[:items]) }
          else
            build_table(group).each { |g| rows << g }
          end
        end
      end
      rows
    end

    def table(items)
      tree = build_tree(items, @rules)
      table = build_table(tree)
      table
    end

    private

    def is_leaf_node(node)
      node.is_a? Array
    end
  end
end
