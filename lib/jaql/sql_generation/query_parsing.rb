module Jaql
  module SqlGeneration
    module QueryParsing

      class InvalidQuery < StandardError ; end

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
                      result << associated_column(ass, col, display_name, subquery_spec)
                    else # from_name is the name of the column or association
                      result << column_or_association(from_name, display_name, subquery_spec)
                    end
                  else # display_name is the name of the column or association
                    result << column_or_association(display_name, nil, subquery_spec)
                  end



                end
              end
            else # TODO raise invalid query
              raise InvalidQuery.new("json field '#{field}' is a #{field.class}")
            end
          end
        end

        result
      end

      def associated_column(ass_name, col_name, display_name, subquery_spec)
        if association = resolver.association_for(ass_name)
          if association.to_one?
            AssociatedColumnField.new(association, col_name, display_name)
          else
            ErrorField.new "cannot parse 'from: #{ass_name}.#{col_name}' because #{ass_name} is a #{association.type} association"
          end
          # new_resolver = resolver.build_from_association(association)
          # subquery     = Query.new(run_context, subquery_spec, new_resolver)

        else
          unknown_field(table_name, real_name, display_name)
        end

      end

      def column_or_association(real_name, display_name=nil, subquery_spec=nil)
        table_name = resolver.table_name
        if column_name = resolver.column_for(real_name)
          ColumnField.new(table_name, column_name, display_name)
        elsif association = resolver.association_for(real_name)
          new_resolver = resolver.build_from_association(association)
          subquery     = Query.new(run_context, subquery_spec, new_resolver)
          AssociationField.new(association, display_name, subquery)
        else
          unknown_field(table_name, real_name, display_name)
        end
      end

      def unknown_field(table_name, real_name, display_name)
        ErrorField.new "unknown column or association '#{table_name}.#{real_name}'"
      end
    end
  end
end
