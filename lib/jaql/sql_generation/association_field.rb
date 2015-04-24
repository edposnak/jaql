module Jaql
  module SqlGeneration
    class AssociationField < Field
      attr_reader :association, :display_name, :subquery
      private :association, :display_name, :subquery

      def initialize(association, display_name=nil, subquery=nil)
        @association  = association
        @display_name = display_name
        @subquery     = subquery
      end

      def to_sql
        comment_sql = "-- #{association.type} #{association.name} (#{association.associated_table})"

        cte = "SELECT #{subquery.fields_sql}\n FROM #{tables_sql}\n WHERE #{where_sql}"
        return_type = association.type == Dart::Association::MANY_TO_ONE_TYPE ? Query::ROW_RETURN_TYPE : Query::ARRAY_RETURN_TYPE
        field_sql = subquery.json_sql(cte, display_name || association.name, return_type)

        [comment_sql, field_sql].join("\n")
      end

      private

      def tables_sql
        sql = quote association.associated_table
        sql << ", #{quote association.join_table}" if is_join?(association)
        sql
      end

      def where_sql
        if default_where = subquery.default_where_sql
        "(#{join_cond_sql}) AND (#{default_where})"
        else
          join_cond_sql
        end
      end

      def join_cond_sql
        if is_join?(association)
          association.join_associations.map(&method(:join_cond_sql_for_direct)).join(' AND ')
        else
          join_cond_sql_for_direct(association)
        end
      end

      def join_cond_sql_for_direct(ass)
        "#{quote ass.child_table}.#{quote ass.foreign_key} = #{quote ass.parent_table}.#{quote ass.primary_key}"
      end

      def is_join?(ass)
        ass.respond_to?(:join_table)
      end
    end
  end
end
