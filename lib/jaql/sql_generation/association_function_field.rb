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

      def initialize(display_name, subquery, function_name)
        super(display_name, subquery)
        @function_name = function_name.to_s.downcase
      end

      private

      def comment_sql
        "-- #{last_association.name}.#{function_name} #{from_comment}"
      end

      def field_sql
        # Consider separate subclasses for AssociationCountField, AssociationExistsField, etc.
        case function_name
        when COUNT_FUNCTION
          "(SELECT COUNT(count_column) FROM (SELECT 1 AS count_column #{selection_sql}) #{quote('count_subquery')}) #{as_display_name_sql}"
        when EXISTS_FUNCTION
          "(SELECT EXISTS (SELECT * #{selection_sql(limit: 1)}) #{as_display_name_sql})"
        end
      end

      def allowed_client_scope_options
        # filter out ORDER, LIMIT and OFFSET since they don't jibe with COUNT and EXISTS
        # TODO consider selectively supporting ORDER, LIMIT and OFFSET if they make sense with other functions
        super - [ORDER_KEY, LIMIT_KEY, OFFSET_KEY]
      end

    end
  end
end
