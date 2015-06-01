module Jaql
  module SqlGeneration
    # Allows for creation of fields from some column on some association, e.g. creator.last_name
    class AssociationFunctionField < AssociationField

      COUNT_FUNCTION = 'count'.freeze
      EXISTS_FUNCTION = 'exists'.freeze

      SUPPORTED_FUNCTIONS = [COUNT_FUNCTION, EXISTS_FUNCTION]
      def self.supports?(function_name)
        SUPPORTED_FUNCTIONS.include?(function_name.downcase)
      end


      attr_reader :function_name
      private :function_name

      def initialize(display_name, association, subquery, function_name)
        super(display_name, association, subquery)
        @function_name = function_name.to_s.downcase
      end

      private

      def comment_sql
        "-- #{association.name}.#{function_name} (from #{association.type} #{association.name})"
      end

      def field_sql
        # filter out ORDER, LIMIT and OFFSET since they don't jibe with COUNT and EXISTS
        subquery_scope_options = subquery.scope_options.slice *(ASSOCIATION_SCOPE_OPTION_KEYS - [ORDER_KEY, LIMIT_KEY, OFFSET_KEY])
        # TODO consider selectively supporting ORDER, LIMIT and OFFSET if they make sense with other functions

        case function_name
        when COUNT_FUNCTION
          "(SELECT COUNT(*) AS #{quote(display_name)}\n  #{from_sql(association)}\n  #{scope_sql(association, subquery_scope_options)})"
        when EXISTS_FUNCTION
          "(SELECT EXISTS (SELECT * #{from_sql(association)}\n  #{scope_sql(association, subquery_scope_options.merge(limit: 1))} ) AS #{quote(display_name)})"
        end
      end
    end
  end
end
