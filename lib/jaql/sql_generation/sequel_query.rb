module Jaql
  module SqlGeneration
    class SequelQuery < RunnableQuery
      private

      def scope_selected_sql
        # TODO implement client-supplied scopes (where, order, limit) at outer layer
        scope.select(Sequel.lit(fields_sql)).sql
      end

      def run(sql_to_run, output_col)
        scope.db[sql_to_run].first[output_col.to_sym]
      end

    end
  end
end
