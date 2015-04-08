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

      # @param [RunContext] run_context defines the state of the runnable query being constructed
      def to_sql(run_context)
        comment_sql = "-- #{association.type} #{association.name} (#{association.associated_table})"
        ass_sql     = "SELECT #{subquery.fields_sql(run_context)} FROM #{tables_sql} WHERE #{join_cond_sql}"
        field_sql   = run_context.json_array_sql(ass_sql, display_name || association.name)
        [comment_sql, field_sql].join("\n")
      end

      private

      def tables_sql
        sql = quote association.associated_table
        sql << ", #{quote association.join_table}" if is_join?(association)
        sql
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
