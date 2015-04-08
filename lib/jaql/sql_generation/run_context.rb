module Jaql
  module SqlGeneration
    # Holds the state of a given run of a query. Right now that just consists of a counter and prefix used to generate
    # temporary relation names as the query is constructed.
    class RunContext
      def initialize(prefix=nil)
        @prefix       = prefix || 'r'
        @relation_num = 0
      end

      def json_array_sql(cte, display_name)
        display_name or raise "display_name cannot be blank"
        json_sql :json_agg, cte, display_name
      end

      def json_row_sql(cte, display_name)
        display_name or raise "display_name cannot be blank"
        json_sql :row_to_json, cte, display_name
      end

      def json_sql(sql_method, cte, display_name)
        rel = tmp_relation_name
        "( SELECT #{sql_method}(#{rel}) AS \"#{display_name}\" FROM (#{cte}) #{rel} )"
      end

      private

      def tmp_relation_name()
        @relation_num += 1
        "#{@prefix}#{@relation_num}"
      end
    end
  end
end

