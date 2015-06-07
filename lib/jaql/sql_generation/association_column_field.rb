module Jaql
  module SqlGeneration
    # Allows for creation of fields from some column on some association, e.g. creator.last_name
    class AssociationColumnField < AssociationField

      attr_reader :column_name
      private :column_name

      def initialize(display_name, subquery, column_name)
        super(display_name, subquery)
        @column_name = column_name
      end

      private

      def comment_sql
        "-- #{last_association.name}.#{column_name} #{from_comment}"
      end

      def projection_sql
        "SELECT #{table_name_sql(last_association)}.#{quote column_name} #{as_display_name_sql}"
      end

      def selection_is_scalar?
        true # no need to JSON encode the return value
      end

    end
  end
end
