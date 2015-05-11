module Jaql
  module SqlGeneration
    module QueryParsing

      class InvalidQuery < StandardError ; end

      # includers must respond_to:
      # query_table_name

      private

      # Protocol
      JSON_KEY = 'json'.freeze
      FROM_KEY = 'from'.freeze

      # parses a spec into a list of Fields, each of which may contain their own lists of fields
      def parse_fields
        result = []

        # TODO allow
        #   topics: { } # without from or json
        #   members: { from: :users } # without json
        if json = spec[JSON_KEY]
          json.each do |field|
            case field
            when String, Symbol
              result << column_or_association(field)
            when Hash
              field.each do |display_name, subquery_or_real_name|
                case subquery_or_real_name
                when String, Symbol
                  real_name = subquery_or_real_name
                  result << column_or_association(real_name, display_name)
                when Hash
                  subquery_spec = subquery_or_real_name
                  # peek into the subquery to get the real association name if different from display name
                  if from_name = subquery_spec[FROM_KEY]
                    ass, col = from_name.split('.')
                    if col # get the value from ass.col
                      result << association_column_or_function(ass, col, display_name, subquery_spec)
                    else # from_name is the name of the column or association
                      result << column_or_association(from_name, display_name, subquery_spec)
                    end
                  else # display_name is the name of the column or association
                    result << column_or_association(display_name, nil, subquery_spec)
                  end
                end
              end
            else
              raise InvalidQuery.new("json field '#{field}' is a #{field.class}")
            end
          end
        end

        result
      end

      def association_column_or_function(ass_name, col_name, display_name, subquery_spec)
        if association = resolver.association_for(ass_name)
          field_class = AssociationFunctionField.supports?(col_name) ? AssociationFunctionField : AssociatedColumnField
          field_class.new(association, col_name, display_name, build_subquery(association, subquery_spec))
        else
          ErrorField.new "unknown association '#{query_table_name}.#{ass_name}' (#{display_name}: #{ass_name}.#{col_name})"
        end

      end

      def column_or_association(real_name, display_name=nil, subquery_spec=nil)
        if column_name = resolver.column_for(real_name)
          ColumnField.new(query_table_name, column_name, display_name)
        elsif association = resolver.association_for(real_name)
          AssociationField.new(association, display_name, build_subquery(association, subquery_spec))
        else
          ErrorField.new "unknown column or association '#{query_table_name}.#{real_name}' (#{display_name})"
        end
      end

      def build_subquery(association, subquery_spec)
        new_resolver = resolver.build_from_association(association)
        # TODO alias any join tables in the association that are the same as resolver.table_name
        table_alias = "#{association.associated_table}_#{run_context.tmp_relation_name}" if association.associated_table == resolver.table_name
        Query.new(run_context, subquery_spec, new_resolver, table_alias)
      end

    end
  end
end
