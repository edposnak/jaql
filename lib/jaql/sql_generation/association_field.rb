module Jaql
  module SqlGeneration
    class AssociationField < Field

      attr_reader :display_name, :subquery
      private :display_name, :subquery

      def initialize(display_name, subquery)
        super(display_name)
        @subquery = subquery
      end

      def to_sql
        [comment_sql, field_sql].join("\n")
      end

      private

      def comment_sql
        "-- #{from_comment} (#{last_association.associated_table})"
      end

      def from_comment
        "(from #{association_chain.map { |a| "#{a.type} #{a.name}" }.join(', ')})"
      end

      def field_sql
        return_type = last_association.to_one? ? Query::ROW_RETURN_TYPE : Query::ARRAY_RETURN_TYPE
        if selection_is_scalar? # return the scalar value (no json) if the last association is *_to_one, otherwise return an array
          return_type ==  Query::ROW_RETURN_TYPE ? "(#{inner_cte_sql})" : "(SELECT array(#{inner_cte_sql}) AS #{display_name})"
        else # return a JSON representation of the row(s)
          subquery.json_sql(inner_cte_sql, display_name, return_type)
        end
      end

      def inner_cte_sql
        "  #{projection_sql}\n  #{selection_sql}"
      end

      def projection_sql
        "SELECT #{subquery.fields_sql}"
      end

      # TODO the associations themselves should provide this SQL, and lean on the ORMs and all their nifty features to
      # produce it. This will address the more complicated :through associations involving long chains of all types of
      # associations. But how to overlay client-provided scopes? Are client-provided scopes useful enough to warrant
      # SQL generation for these associations? Is there any value in generating the SQL here, or just a maintenance nightmare?


      # SELECT "broadcasts"."id" FROM "broadcasts"
      # INNER JOIN "broadcasts" "broadcasts_child_undo_broadcasts_join" ON "broadcasts"."broadcast_to_undo_id" = "broadcasts_child_undo_broadcasts_join"."id"
      # INNER JOIN "users" ON "broadcasts_child_undo_broadcasts_join"."created_by" = "users"."id"
      # WHERE "broadcasts"."state" = 0 AND "users"."deleted" = 'f' AND "users"."client_id" = 70

      # TODO sanitize all WHERE and ORDER clauses against SQL injection
      def selection_sql(final_scope_options={})
        # TODO: BROKEN!!! Use table aliases when associations reference the same table
        from_tables = association_chain.flat_map do |association|
          [
            quote(association.associated_table),
            (quote(association.join_table) if is_join?(association))
          ].compact
        end
        from_sql = "FROM #{from_tables.join(', ')}"

        # use only where for intermediate scopes
        *intermediate_sqs, last_subquery = subquery_chain
        intermediate_where_clauses = intermediate_sqs.flat_map do |subquery|
          [
            join_cond_sql(subquery.association), # consider using FROM t1 INNER JOIN t2 ON t1.x = t2.y
            subquery.association.scope.stringify_keys[WHERE_KEY]
          ]
        end.compact

        # final_scope_options always override any client-supplied scope options, which override association scope options
        ass_scope = last_subquery.association.scope.stringify_keys
        client_scope = last_subquery.scope_options.stringify_keys.slice(*allowed_client_scope_options)
        final_scope = final_scope_options.stringify_keys

        where_sql = "WHERE (#{join_cond_sql(last_subquery.association)})"
        intermediate_where_clauses.each { |where_clause| where_sql << " AND (#{where_clause})" }

        # Combine all WHEREs
        client_scope[WHERE_KEY] and where_sql << " AND (#{client_scope[WHERE_KEY]})"
        ass_scope[WHERE_KEY] and where_sql << " AND (#{ass_scope[WHERE_KEY]})"
        final_scope[WHERE_KEY] and where_sql << " AND (#{final_scope[WHERE_KEY]})"

        # Cascade ORDER, LIMIT and OFFSET
        if the_order = final_scope[ORDER_KEY] || client_scope[ORDER_KEY] || ass_scope[ORDER_KEY]
          where_sql << " ORDER BY (#{the_order})"
        end

        if the_limit = final_scope[LIMIT_KEY] || client_scope[LIMIT_KEY] || ass_scope[LIMIT_KEY]
          where_sql << " LIMIT #{the_limit.to_i}"
        end

        if the_offset = final_scope[OFFSET_KEY] || client_scope[OFFSET_KEY] || ass_scope[OFFSET_KEY]
          where_sql << " OFFSET #{the_offset.to_i}"
        end

        "#{from_sql}\n  #{where_sql}"
      end

      def selection_is_scalar?
        false
      end

      def allowed_client_scope_options
        ASSOCIATION_SCOPE_OPTION_KEYS - [WHERE_KEY]
      end

      def last_association
        association_chain.last
      end

      def association_chain
        subquery_chain.map(&:association)
      end

      def subquery_chain
        [subquery]
      end


      #########################################################################################################

      # private
      include Jaql::Protocol

      def table_name_sql(association)
        quote(association.associated_table)
      end


      def join_alias_for(join_table, ass_name)
        "#{join_table}_#{ass_name}_join"
      end

      # super private

      def is_join?(association)
        association.respond_to?(:join_table)
      end

      def join_cond_sql(association)
        # if associated_table_alias
        #   # TODO clean up this ugly mess
        #   case association
        #   when Dart::ManyToManyAssociation
        #     *ass_chain, target_ass = association.join_associations
        #     ass_chain.map(&method(:join_cond_sql_for_direct)).join(' AND ') + " AND #{join_cond_sql_for_direct(target_ass, nil, associated_table_alias)}"
        #   when Dart::OneToOneAssociation, Dart::OneToManyAssociation
        #     join_cond_sql_for_direct(association, associated_table_alias, nil)
        #   when Dart::ManyToOneAssociation
        #     join_cond_sql_for_direct(association, nil, associated_table_alias)
        #   end
        # else
          ass_chain = is_join?(association) ? association.join_associations : [association]
          ass_chain.map(&method(:join_cond_sql_for_direct)).join(' AND ')
        # end
      end

      def join_cond_sql_for_direct(ass, child_table_alias=nil, parent_table_alias=nil)
        "#{quote(child_table_alias || ass.child_table)}.#{quote ass.foreign_key} = #{quote(parent_table_alias || ass.parent_table)}.#{quote ass.primary_key}"
      end


    end
  end
end
