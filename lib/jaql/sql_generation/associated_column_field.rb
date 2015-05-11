module Jaql
  module SqlGeneration
    # Allows for creation of fields from some column on some association, e.g. creator.last_name
    class AssociatedColumnField < Field
      include AssociationSQL

      attr_reader :association, :column_name, :display_name
      private :association, :column_name, :display_name

      def initialize(association, column_name, display_name=nil, subquery=nil)
        @association = association
        @column_name = column_name
        @display_name = display_name
        @subquery = subquery
        @associated_table_alias = subquery.table_name_alias
      end

      def to_sql
        [comment_sql, field_sql].join("\n")
      end

      private

      def comment_sql
        "-- #{association.associated_table}.#{column_name} (from #{association.type} #{association.name})"
      end

      def field_sql
        select_sql = "SELECT #{table_name_sql(association)}.#{quote column_name} AS #{quote(display_name)}"
        cte = "#{select_sql}\n  #{from_sql(association)}\n  #{scope_sql(association)}"

        # return the column value if the association is *_to_one, otherwise return an array
        association.to_one? ? "(#{cte})" : "(SELECT array(#{cte}) AS #{display_name})"
      end

    end
  end
end
