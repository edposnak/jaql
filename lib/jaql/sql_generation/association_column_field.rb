module Jaql
  module SqlGeneration
    # Allows for creation of fields from some column on some association, e.g. creator.last_name
    class AssociationColumnField < AssociationField

      attr_reader :column_name
      private :column_name

      def initialize(display_name, association, subquery, column_name)
        super(display_name, association, subquery)
        @column_name = column_name
      end

      private

      def comment_sql
        "-- #{association.name}.#{column_name} (from #{association.type} #{association.name})"
      end

      def field_sql
        select_sql = "SELECT #{table_name_sql(association)}.#{quote column_name} AS #{quote(display_name)}"
        cte = "#{select_sql}\n  #{from_sql(association)}\n  #{scope_sql(association, subquery.scope_options)}"

        # return the column value if the association is *_to_one, otherwise return an array
        association.to_one? ? "(#{cte})" : "(SELECT array(#{cte}) AS #{display_name})"
      end

    end
  end
end
