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

      def initialize(association, function_name, display_name=nil, subquery=nil)
        super(association, display_name, subquery)
        @function_name = function_name.to_s.downcase
      end

      private

      def comment_sql
        "-- #{association.associated_table}.#{function_name} (from #{association.type} #{association.name})"
      end

      def field_sql
        case function_name
        when COUNT_FUNCTION
          "(SELECT COUNT(*) AS #{quote(display_name)}\n  #{from_sql(association)}\n  #{scope_sql(association)})"
        when EXISTS_FUNCTION
          "(SELECT EXISTS (SELECT * #{from_sql(association)}\n  #{scope_sql(association, limit: 1)} ) AS #{quote(display_name)})"
        end
      end
    end
  end
end
