module Jaql
  module SqlGeneration
    # A RunnableQuery extends Query with the ability to produce JSON from postgres by applying spec to scope
    class RunnableQuery < Query
      JSON_RESULT_COL_NAME = 'json_data'.freeze

      attr_reader :scope
      private :scope

      def initialize(scope, spec)
        @scope = scope
        super(ResolverFactory.resolver_for(scope), spec)
      end

      # Run the query and produce JSON
      def json_array
        run_returning :array
      end

      def json_row
        run_returning :row
      end

      private

      def run_returning(return_type)
        run_context = RunContext.new
        runner      = ResolverFactory.runner_for(scope)

        if runner == :sequel
          scope_selected_sql = scope.select(Sequel.lit(fields_sql(run_context))).sql

          sql_to_run = sql_for(scope_selected_sql, return_type, run_context)

          scope.db[sql_to_run].first[JSON_RESULT_COL_NAME.to_sym]

        elsif runner == :active_record

          scope_selected_sql = scope.select(fields_sql(run_context)).to_sql

          sql_to_run = sql_for(scope_selected_sql, return_type, run_context)

          scope.connection.execute(sql_to_run).first[JSON_RESULT_COL_NAME]
        else
          raise "unknown runner type #{runner}"
        end
      end

      def sql_for(scope_selected_sql, return_type, run_context)
        sql = case return_type
              when :array
                run_context.json_array_sql(scope_selected_sql, JSON_RESULT_COL_NAME)
              when :row
                run_context.json_row_sql(scope_selected_sql, JSON_RESULT_COL_NAME)
              else
                fail "unknown return type: '#{return_type}'"
              end
        puts "\n\n****************************** Sequel: sql_to_run = \n\n#{sql} \n\n"
        sql
      end

    end
  end
end
