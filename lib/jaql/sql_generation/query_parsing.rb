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
              result << column_or_association_field(nil, field)

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
          if association = resolver.association_for(ass_name)
            *args = display_name, association, build_subquery(association, jaql_spec), col_or_fun_name
            AssociationFunctionField.supports?(col_or_fun_name) ? AssociationFunctionField.new(*args) : AssociationColumnField.new(*args)
          else
            ErrorField.new "unknown association '#{query_table_name}.#{ass_name}' (#{display_name}: #{ass_name}.#{col_or_fun_name})"
          end

        elsif jaql_spec.association_str?
          ass_name = jaql_spec.from
          if association = resolver.association_for(ass_name)
            AssociationInterpolatedStringField.new(display_name, association, build_subquery(association, jaql_spec), jaql_spec.str)
          else
            ErrorField.new "unknown association '#{query_table_name}.#{ass_name}' (#{display_name}: from: #{ass_name} str: #{jaql_spec.str})"
          end

        elsif jaql_spec.aliased_column_or_association?
          real_name = jaql_spec.from
          column_or_association_field(display_name, real_name, jaql_spec)

        elsif jaql_spec.aliased_str?
          InterpolatedStringField.new(display_name, query_table_name, jaql_spec.str)

        elsif jaql_spec.non_aliased_column_or_association?
          column_or_association_field(nil, display_name, jaql_spec) # display_name is the real name of the column or association

        else
          raise "Unparseable query spec: #{display_name}: #{hash_spec}"
        end
      end

      def column_or_association_field(display_name, real_name, jaql_spec=nil)
        jaql_spec ||= Jaql::Spec.new # if no spec given, create a blank one
        if column_name = resolver.column_for(real_name)
          ColumnField.new(query_table_name, column_name, display_name)
        elsif association = resolver.association_for(real_name)
          AssociationField.new(display_name, association, build_subquery(association, jaql_spec))
        else
          ErrorField.new "unknown column or association '#{query_table_name}.#{real_name}' (display_name=#{display_name}, resolver model=#{resolver.send(:this_model_class)})"
        end
      end

      # @param [Dart::Association] association
      # @param [Jaql::Spec] jaql_spec
      def build_subquery(association, jaql_spec)
        new_resolver = resolver.build_from_association(association)
        # TODO alias any join tables in the association that are the same as resolver.table_name
        table_alias = "#{association.associated_table}_#{run_context.tmp_relation_name}" if association.associated_table == resolver.table_name
        Query.new(run_context, jaql_spec, new_resolver, table_alias)
      end

    end
  end
end
