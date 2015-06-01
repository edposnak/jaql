module Jaql
  module SqlGeneration
    class AssociationInterpolatedStringField < AssociationField
      include StringInterpolation

      attr_reader :display_name, :table_name, :interpolated_string
      private :display_name, :table_name, :interpolated_string

      def initialize(display_name, association, subquery, interpolated_string)
        super(display_name, association, subquery)
        @interpolated_string = interpolated_string
      end

      private

      def comment_sql
        "-- #{interpolated_string} (from #{association.type} #{association.name})"
      end

      def field_sql
        select_sql = "SELECT #{str_sql_for(interpolated_string, table_name_sql(association))}"
        cte = "#{select_sql}\n  #{from_sql(association)}\n  #{scope_sql(association, subquery.scope_options)}"

        # return the column value if the association is *_to_one, otherwise return an array
        association.to_one? ? "(#{cte})" : "(SELECT array(#{cte}) AS #{display_name})"
      end

    end
  end
end
