module Jaql
  module SqlGeneration
    # Allows for creation of fields from some column on some association, e.g. creator.last_name
    class AssociationFunctionField < Field

      include AssociationSQL

      COUNT_FUNCTION = 'count'
      EXISTS_FUNCTION = 'exists'

      SUPPORTED_FUNCTIONS = [COUNT_FUNCTION, EXISTS_FUNCTION]
      def self.supports?(function_name)
        SUPPORTED_FUNCTIONS.include?(function_name.downcase)
      end


      attr_reader :association, :function_name, :display_name
      private :association, :function_name, :display_name

      def initialize(association, function_name, display_name=nil, subquery=nil)
        @association = association
        @function_name = function_name.to_s.downcase
        @display_name = display_name
        @subquery = subquery
        @associated_table_alias = subquery.table_name_alias
      end

      def to_sql
        [comment_sql, field_sql].join("\n")
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
