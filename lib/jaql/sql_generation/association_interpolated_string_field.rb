module Jaql
  module SqlGeneration
    class AssociationInterpolatedStringField < AssociationField
      include StringInterpolation

      attr_reader :interpolated_string
      private :interpolated_string

      def initialize(display_name, subquery, interpolated_string)
        super(display_name, subquery)
        @interpolated_string = interpolated_string
      end

      private

      def comment_sql
        "-- #{interpolated_string} #{from_comment}"
      end

      def selection_is_scalar?
        true # no need to JSON encode the return value
      end

      def projection_sql
        "SELECT #{str_sql_for(interpolated_string, table_name_sql(last_association))}"
      end

    end
  end
end
