module Jaql
  module SqlGeneration
    module AssociationSQL
      # TODO the associations themselves should provide this SQL, and lean on the ORMs and all their nifty features to
      # produce it. This will address the more complicated :through associations involving long chains of all types of
      # associations

      private

      def is_join?(ass)
        ass.respond_to?(:join_table)
      end

      def join_cond_sql_for_direct(ass)
        "#{quote ass.child_table}.#{quote ass.foreign_key} = #{quote ass.parent_table}.#{quote ass.primary_key}"
      end

      def join_cond_sql
        if is_join?(association)
          association.join_associations.map(&method(:join_cond_sql_for_direct)).join(' AND ')
        else
          join_cond_sql_for_direct(association)
        end
      end

      def scope_sql
        # TODO offset etc.
        sql = "WHERE (#{join_cond_sql})"
        if ass_where = association.scope[:where]
          sql << " AND (#{ass_where})"
        end
        if ass_order = association.scope[:order]
          sql << " ORDER BY (#{ass_order})"
        end
        if ass_limit = association.scope[:limit]
          sql << " LIMIT (#{ass_limit})"
        end
        sql
      end

      def from_sql
        sql = "FROM #{quote association.associated_table}"
        sql << ", #{quote association.join_table}" if is_join?(association)
        sql
      end

      def select_sql
        "SELECT #{subquery.fields_sql}"
      end
    end
  end
end
