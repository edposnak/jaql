module Jaql
  module SqlGeneration
    module AssociationSQL
      # TODO the associations themselves should provide this SQL, and lean on the ORMs and all their nifty features to
      # produce it. This will address the more complicated :through associations involving long chains of all types of
      # associations

      # includers must respond_to:
      # @associated_table_alias

      private

      def table_name_sql(association)
        quote(@associated_table_alias || association.associated_table)
      end

      def from_sql(association)
        ass_table = "#{quote association.associated_table} #{@associated_table_alias ? " #{quote @associated_table_alias}" : ''}"
        join_table = quote(association.join_table) if is_join?(association)
        "FROM #{[ass_table, join_table].compact.join(', ')}"
      end

      def scope_sql(association, options={})
        ass_scope = association.scope
        sql = "WHERE (#{join_cond_sql(association)})"

        # Client WHERE combines with association WHERE
        if client_where = options[:where]
          sql << " AND (#{client_where})"
        end
        if ass_where = ass_scope[:where]
          sql << " AND (#{ass_where})"
        end

        # Client provided ORDER and LIMIT override that of the association
        if the_order = options[:order] || ass_scope[:order]
          sql << " ORDER BY (#{the_order})"
        end

        if ass_limit = options[:limit] || ass_scope[:limit]
          sql << " LIMIT (#{ass_limit})"
        end

        # TODO OFFSET etc.
        sql
      end

      # super private

      def is_join?(ass)
        ass.respond_to?(:join_table)
      end

      def join_cond_sql(association)
        if @associated_table_alias
          # TODO clean up this ugly mess
          case association
          when Dart::ManyToManyAssociation
            *ass_chain, target_ass = association.join_associations
            ass_chain.map(&method(:join_cond_sql_for_direct)).join(' AND ') + " AND #{join_cond_sql_for_direct(target_ass, nil, @associated_table_alias)}"
          when Dart::OneToOneAssociation, Dart::OneToManyAssociation
            join_cond_sql_for_direct(association, @associated_table_alias, nil)
          when Dart::ManyToOneAssociation
            join_cond_sql_for_direct(association, nil, @associated_table_alias)
          end
        else
          ass_chain = is_join?(association) ? association.join_associations : [association]
          ass_chain.map(&method(:join_cond_sql_for_direct)).join(' AND ')
        end
      end

      def join_cond_sql_for_direct(ass, child_table_alias=nil, parent_table_alias=nil)
        "#{quote(child_table_alias || ass.child_table)}.#{quote ass.foreign_key} = #{quote(parent_table_alias || ass.parent_table)}.#{quote ass.primary_key}"
      end

    end
  end
end
