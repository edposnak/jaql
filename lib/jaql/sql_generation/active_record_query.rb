module Jaql
  module SqlGeneration
    # A RunnableQuery extends Query with the ability to produce JSON from postgres by applying spec to scope
    class ActiveRecordQuery < RunnableQuery
      private

      def scope_selected_sql
        # TODO implement client-supplied scopes (where, order, limit) at outer layer
        scope.select(fields_sql).to_sql
      end

      def run(sql_to_run, output_col)
        scope.connection.execute(sql_to_run).first[output_col.to_s]
      end

    end
  end
end
