module Jaql
  module SqlGeneration
    # Allows for creation of fields from some column on some association, e.g. creator.last_name
    class AssociatedColumnField < Field
      include AssociationSQL

      attr_reader :association, :column_name, :display_name
      private :association, :column_name, :display_name

      def initialize(association, column_name, display_name=nil, subquery_spec=nil)
        @association = association
        @column_name = column_name
        @display_name = display_name if column_name != display_name
      end

      def to_sql
        # e.g. (SELECT "users"."last_name" AS creator_name FROM "users" WHERE ("broadcasts"."created_by" = "users"."id") AND ("users"."deleted" = 'f'))
        comment_sql = "-- #{association.associated_table}.#{column_name} (from #{association.type} #{association.name})"
        field_sql = "(#{select_sql} #{from_sql} #{scope_sql})"
        [comment_sql, field_sql].join("\n")
      end

      def select_sql
        "SELECT #{quote association.associated_table}.#{quote column_name}#{display_name && " AS #{quote(display_name)}"} "
      end

    end
  end
end
