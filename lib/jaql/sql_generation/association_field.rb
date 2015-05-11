module Jaql
  module SqlGeneration
    class AssociationField < Field
      include AssociationSQL

      attr_reader :association, :display_name, :subquery
      private :association, :display_name, :subquery


      # e.g. child_undo_broadcast_ass, :child_undo_broadcast_id, json: [:id, :start_time]
      def initialize(association, display_name=nil, subquery=nil)
        @association  = association
        @display_name = display_name
        @subquery     = subquery
        @associated_table_alias = subquery.table_name_alias
      end

      def to_sql
        [comment_sql, field_sql].join("\n")
      end

      private

      def comment_sql
        "-- #{association.type} #{association.name} (#{association.associated_table})"
      end

      def field_sql
        select_sql = "SELECT #{subquery.fields_sql}"
        cte = "#{select_sql}\n  #{from_sql(association)}\n  #{scope_sql(association, subquery.scope_options)}"
        return_type = association.to_one? ? Query::ROW_RETURN_TYPE : Query::ARRAY_RETURN_TYPE
        field_sql = subquery.json_sql(cte, display_name || association.name, return_type)
      end

    end
  end
end
