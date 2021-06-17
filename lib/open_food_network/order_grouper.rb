# frozen_string_literal: true

module OpenFoodNetwork
  class OrderGrouper
    def initialize(rules, column_constructors, report = nil)
      @rules = rules
      @column_constructors = column_constructors
      @report = report
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
        rows << build_row(groups)
      else
        groups.each do |key, group|
          if key == :summary_row
            rows << build_summary_row(group[:columns], group[:items])
          else
            build_table(group).each { |g| rows << g }
          end
        end
      end
      rows
    end

    def table(items)
      tree = build_tree(items, @rules)
      build_table(tree)
    end

    private

    def build_cell(column_constructor, items)
      if column_constructor.is_a?(Symbol)
        @report.__send__(column_constructor, items)
      else
        column_constructor.call(items)
      end
    end

    def build_row(groups)
      @column_constructors.map do |column_constructor|
        build_cell(column_constructor, groups)
      end
    end

    def build_summary_row(summary_row_column_constructors, items)
      summary_row_column_constructors.map do |summary_row_column_constructor|
        build_cell(summary_row_column_constructor, items)
      end
    end

    def is_leaf_node(node)
      node.is_a? Array
    end
  end
end
