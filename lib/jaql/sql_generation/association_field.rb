module Jaql
  module SqlGeneration
    class AssociationField < Field

      attr_reader :association, :display_name, :subquery
      private :association, :display_name, :subquery


      # e.g. child_undo_broadcast_ass, :child_undo_broadcast_id, json: [:id, :start_time]
      def initialize(association, display_name=nil, subquery=nil)
        @association  = association
        @display_name = display_name
        @subquery     = subquery
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

      #########################################################################################################

      # TODO the associations themselves should provide this SQL, and lean on the ORMs and all their nifty features to
      # produce it. This will address the more complicated :through associations involving long chains of all types of
      # associations. But how to overlay client-provided scopes? Are client-provided scopes useful enough to warrant
      # SQL generation for these associations? Is there any value in generating the SQL here, or just a maintenance nightmare?

      # private
      include Jaql::Protocol

      # used when the associated table name is already used
      def associated_table_alias
        subquery.table_name_alias
      end

      def table_name_sql(association)
        quote(associated_table_alias || association.associated_table)
      end

      def from_sql(association)
        ass_table = "#{quote association.associated_table} #{associated_table_alias ? " #{quote associated_table_alias}" : ''}"
        join_table = quote(association.join_table) if is_join?(association)
        "FROM #{[ass_table, join_table].compact.join(', ')}"
      end

      # TODO sanitize all WHERE and ORDER clauses against SQL injection
      def scope_sql(association, options={})
        ass_scope = association.scope.stringify_keys
        client_scope = options.stringify_keys

        ASSOCIATION_SCOPE_OPTION_KEYS
        sql = "WHERE (#{join_cond_sql(association)})"

        # Client WHERE combines with association WHERE
        client_scope[WHERE_KEY] and sql << " AND (#{client_scope[WHERE_KEY]})"
        ass_scope[WHERE_KEY] and sql << " AND (#{ass_scope[WHERE_KEY]})"

        # Client provided ORDER, LIMIT and OFFSET override any on the association
        if the_order = client_scope[ORDER_KEY] || ass_scope[ORDER_KEY]
          sql << " ORDER BY (#{the_order})"
        end

        if the_limit = client_scope[LIMIT_KEY] || ass_scope[LIMIT_KEY]
          sql << " LIMIT #{the_limit.to_i}"
        end

        if the_offset = client_scope[OFFSET_KEY] || ass_scope[OFFSET_KEY]
          sql << " OFFSET #{the_offset.to_i}"
        end

        sql
      end

      # super private

      def is_join?(ass)
        ass.respond_to?(:join_table)
      end

      def join_cond_sql(association)
        if associated_table_alias
          # TODO clean up this ugly mess
          case association
          when Dart::ManyToManyAssociation
            *ass_chain, target_ass = association.join_associations
            ass_chain.map(&method(:join_cond_sql_for_direct)).join(' AND ') + " AND #{join_cond_sql_for_direct(target_ass, nil, associated_table_alias)}"
          when Dart::OneToOneAssociation, Dart::OneToManyAssociation
            join_cond_sql_for_direct(association, associated_table_alias, nil)
          when Dart::ManyToOneAssociation
            join_cond_sql_for_direct(association, nil, associated_table_alias)
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
