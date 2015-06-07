module Jaql
  module SqlGeneration
    # A RunnableQuery extends Query with the ability to produce JSON from postgres by applying raw_spec to scope
    class RunnableQuery < Query
      extend RunnableQueryFactoryMethods

      abstract_method :scope_selected_sql, :run

      attr_reader :scope
      private :scope

      def initialize(scope, raw_spec, resolver)
        @scope = scope
        super(Context.new, raw_spec, resolver)
      end

      # Run the query and produce JSON
      JSON_RESULT_COL_NAME = 'json_data'.freeze

      def json_array
        run_returning ARRAY_RETURN_TYPE
      end

      def json_row
        run_returning ROW_RETURN_TYPE
      end

      def run_returning(return_type)
        run(json_sql(scope_selected_sql, JSON_RESULT_COL_NAME, return_type), JSON_RESULT_COL_NAME)
      end

      # The context of a particular run
      # Currently just a temporary relation name generator
      class Context
        def initialize(prefix=nil)
          @prefix       = prefix || 'r'
          @relation_num = 0
        end

        def tmp_relation_name()
          @relation_num += 1
          "#{@prefix}#{@relation_num}"
        end
      end
    end

  end
end
