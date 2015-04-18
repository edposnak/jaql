module Jaql
  module SqlGeneration
    module QueryParsing
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
                  subquery  = subquery_or_real_name
                  # peek into the subquery to get the real association name if different from display name
                  real_name = subquery[FROM_KEY] || display_name
                  result << column_or_association(real_name, display_name, subquery)
                end
              end
            else # TODO raise invalid query
              puts "UNKNOWN: '#{field}'"
            end
          end
        end

        result
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
          puts "unknown #{table_name}.#{real_name}"
          UnknownField.new(real_name, display_name, subquery)
        end
      end
    end
  end
end
