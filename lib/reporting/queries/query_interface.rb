# frozen_string_literal: true

require "arel-helpers"

module Reporting
  module Queries
    class QueryInterface < ::ArelHelpers::QueryBuilder
      include Arel::Nodes

      def coalesce(field, default = 0)
        NamedFunction.new("COALESCE", [field, default])
      end

      def sum_values(field, default = 0)
        NamedFunction.new("SUM", [coalesce(field, default)])
      end

      def sum_grouped(field, _default = 0)
        Case.new(sql_grouping(grouping_fields)).when(0).then(field.maximum).else(field.sum)
      end

      def sum_new(field, _default = 0)
        Case.new(sql_grouping(grouping_fields)).when(0).then(field.maximum).else(sum_values(field))
      end

      def round(field, places: 2)
        NamedFunction.new("ROUND", [field, places])
      end

      def association(base_class, association, alias_node = nil, join_type = InnerJoin)
        options = alias_node.present? ? { aliases: [alias_node] } : {}

        Arel.sql(base_class.join_association(association, join_type, options).first.to_sql)
      end

      def arel_join(join)
        Arel.sql(join.first.to_sql)
      end

      def join_source(join_association)
        join_association[0].right
      end

      def default_value(field)
        field.maximum
      end

      def default_blank(field)
        Case.new(sql_grouping(grouping_fields)).when(0).then(field.maximum).else(empty_string)
      end

      def default_string(field, string)
        Case.new(sql_grouping(grouping_fields)).when(0).then(field.maximum).else(quoted(string))
      end

      def default_summary(field)
        Case.new(sql_grouping(grouping_fields)).when(0).then(field.maximum).else(empty_string)
      end

      def boolean_blank(field, true_string = I18n.t(:yes), false_string = I18n.t(:no))
        Case.new(sql_grouping(grouping_fields)).when(0).
          then(pretty_boolean(field, true_string, false_string).maximum).
          else(empty_string)
      end

      def pretty_boolean(field, true_string, false_string)
        Case.new(field).when(true).
          then(Arel.sql("'#{true_string}'")).
          else(Arel.sql("'#{false_string}'"))
      end

      def cast(field, type)
        NamedFunction.new("CAST", [field.as(type)])
      end

      def null_if(field, nullif)
        NamedFunction.new("NULLIF", [field, nullif])
      end

      def parenthesise(args)
        Grouping.new(args)
      end

      def nullify_empty_strings(field)
        null_if(field, empty_string)
      end

      def empty_string
        raw("''")
      end

      def sql_concat(*args)
        NamedFunction.new("CONCAT", args)
      end

      def raw(string)
        SqlLiteral.new(string)
      end

      def quoted(string)
        Quoted.new(string)
      end

      def sql_grouping(groupings = grouping_fields)
        NamedFunction.new("GROUPING", [groupings])
      end

      def grouping_sets(groupings)
        GroupingSet.new(groupings)
      end

      def sql_case(expression)
        Case.new(expression)
      end

      def rollup(groupings)
        RollUp.new(groupings)
      end

      def raw_result
        ActiveRecord::Base.connection.exec_query(query.to_sql)
      end
    end
  end
end
