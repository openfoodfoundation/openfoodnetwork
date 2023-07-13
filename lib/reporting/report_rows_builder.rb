# frozen_string_literal: true

module Reporting
  class ReportRowsBuilder
    attr_reader :report

    def initialize(report, current_user)
      @report = report
      @builder = ReportRowBuilder.new(report, current_user)
    end

    # Structured data by groups. This tree is used to render
    # the grouped rows including group header and group summary_row if needed
    def grouped_data
      @grouped_data ||= build_tree(computed_data, report.formatted_rules)
    rescue NotImplementedError
      nil
    end

    # Array of rows, each row being an OpenStruct with the computed data
    # Exple [
    #   { producer: "Freddy Shop", shop: true },
    #   { producer: "Mary Farm", shop: false },
    # ]
    def rows
      @rows ||= extract_rows(grouped_data, [])
    end

    # Array of rows, each row being a simple array with the data
    # Exple [
    #   ["Freddy Shop", true],
    #   ["Mary Farm", false],
    # ]
    def table_rows
      @table_rows ||= rows.map(&:to_h).map(&:values)
    end

    private

    def computed_data
      return @computed_data if defined? @computed_data

      @computed_data = report.query_result.map { |item|
        row = @builder.build_row(item)
        OpenStruct.new(item: item, full_row: row, row: @builder.slice_and_format_row(row))
      }

      @computed_data.uniq! { |data| data.row.to_h.values } if @report.skip_duplicate_rows?

      @computed_data
    end

    def extract_rows(data, result)
      data.each do |group_or_row|
        if group_or_row[:is_group].present?
          # Header Row
          if group_or_row[:header].present? && report.display_header_row?
            result << OpenStruct.new(header: group_or_row[:header])
          end
          # Normal Row
          extract_rows(group_or_row[:data], result)
          # Summary Row
          if group_or_row[:summary_row].present? && report.display_summary_row?
            result << group_or_row[:summary_row]
          end
        else
          result << group_or_row.row
        end
      end
      result
    end

    def build_tree(datas, remaining_rules)
      return datas if remaining_rules.empty?

      rules = remaining_rules.clone
      group_and_sort(rules.delete_at(0), rules, datas)
    end

    def group_and_sort(rule, remaining_rules, datas)
      result = []
      groups = group_data_with_rule(datas, rule)
      sorted_groups = sort_groups_with_rule(groups, rule)

      sorted_groups.each do |group_value, group_datas|
        result << {
          is_group: true,
          header: @builder.build_header(rule, group_value, group_datas),
          header_class: rule[:header_class],
          summary_row: @builder.build_summary_row(rule, group_value, group_datas),
          summary_row_class: rule[:summary_row_class],
          data: build_tree(group_datas, remaining_rules)
        }
      end
      result
    end

    def group_data_with_rule(datas, rule)
      datas.group_by { |data|
        if rule[:group_by].is_a?(Symbol)
          data.full_row[rule[:group_by]]
        else
          rule[:group_by].call(data.item, data.full_row)
        end
      }
    end

    def sort_groups_with_rule(groups, rule)
      groups.sort_by do |group_key, _items|
        # By default sort with the group_key if no sort_by rule is present
        if rule[:sort_by].present?
          rule[:sort_by].call(group_key)
        else
          # downcase for better comparaison
          group_key.is_a?(String) ? group_key.downcase : group_key.to_s
        end
      end.to_h
    end
  end
end
