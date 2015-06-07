module Jaql
  module SqlGeneration
    module QueryParsing
      include Jaql::Protocol

      class InvalidQuery < StandardError ; end

      # includers must respond_to:
      # query_table_name

      private

      # parses a spec into a list of Fields, each of which may contain their own specs
      # @param [Jaql::Spec] jaql_spec
      def parse_fields(jaql_spec)
        result = []

        # TODO allow
        #   topics: { } # without from or json
        #   members: { from: :users } # without json
        # TODO make all of these KEYS case-insensitive

        if json = jaql_spec.json
          json.each do |field|
            case field
            when String, Symbol # field is the real name
              result << column_or_association_field(field, field)

            when Hash
              field.each do |display_name, right_hand_side|
                case right_hand_side
                when String, Symbol # right_hand_side is the real name
                  result << column_or_association_field(display_name, right_hand_side)
                when Hash # right_hand_side is a query spec
                  result << field_from_spec(display_name, Jaql::Spec.new(right_hand_side))
                end
              end
            else
              raise InvalidQuery.new("json field '#{field}' is a #{field.class}")
            end
          end
        end

        result
      end

      # @param [String] display_name the name of the field in the output JSON
      # @param [Jaql::Spec] jaql_spec a JSON Query specification
      def field_from_spec(display_name, jaql_spec)
        if jaql_spec.association_column_or_function?
          ass_name, col_or_fun_name = jaql_spec.association_and_column_or_function
          if association1 = resolver.association_for(ass_name)
            subquery = build_subquery(association1, jaql_spec)
            if association2 = subquery.association_for(col_or_fun_name)
              subquery2 = build_subquery(association2, jaql_spec) # the jaql spec applies to the 2nd association
              AssociationAssociationField.new(display_name, subquery, subquery2)
            elsif col = subquery.column_for(col_or_fun_name)
              AssociationColumnField.new(display_name, subquery, col_or_fun_name)
            elsif AssociationFunctionField.supports?(col_or_fun_name)
              AssociationFunctionField.new(display_name, subquery, col_or_fun_name)
            else
              ErrorField.new "unknown association '#{subqery.query_table_name}.#{col_or_fun_name}' (#{display_name}: #{ass_name}.#{col_or_fun_name})"
            end
          else
            ErrorField.new "unknown association '#{query_table_name}.#{ass_name}' (#{display_name}: #{ass_name}.#{col_or_fun_name})"
          end

        elsif jaql_spec.association_str?
          ass_name = jaql_spec.from
          if association = resolver.association_for(ass_name)
            AssociationInterpolatedStringField.new(display_name, build_subquery(association, jaql_spec), jaql_spec.str)
          else
            ErrorField.new "unknown association '#{query_table_name}.#{ass_name}' (#{display_name}: from: #{ass_name} str: #{jaql_spec.str})"
          end

        elsif jaql_spec.aliased_column_or_association?
          real_name = jaql_spec.from
          column_or_association_field(display_name, real_name, jaql_spec)

        elsif jaql_spec.aliased_str?
          InterpolatedStringField.new(display_name, query_table_name, jaql_spec.str)

        elsif jaql_spec.non_aliased_column_or_association?
          column_or_association_field(display_name, display_name, jaql_spec) # display_name is the real name of the column or association

        else
          raise "Unparseable query spec: #{display_name}: #{hash_spec}"
        end
      end

      def column_or_association_field(display_name, real_name, jaql_spec=nil)
        jaql_spec ||= Jaql::Spec.new # if no spec given, create a blank one
        if column_name = resolver.column_for(real_name)
          ColumnField.new(display_name, query_table_name, column_name)
        elsif association = resolver.association_for(real_name)
          AssociationField.new(display_name, build_subquery(association, jaql_spec))
        else
          ErrorField.new "unknown column or association '#{query_table_name}.#{real_name}' (display_name=#{display_name}, resolver model=#{resolver.send(:this_model_class)})"
        end
      end

      # @param [Dart::Association] association
      # @param [Jaql::Spec] jaql_spec
      def build_subquery(association, jaql_spec)
        Subquery.new(run_context, jaql_spec, association)
      end

    end
  end
end
