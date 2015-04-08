module Jaql
  module SqlGeneration
    class ColumnField < Field
      attr_reader :table_name, :column_name, :display_name
      private :table_name, :column_name, :display_name

      def initialize(table_name, column_name, display_name=nil, subquery_spec=nil)
        @table_name, @column_name = table_name, column_name
        @display_name = display_name if column_name != display_name
      end

      # @param [RunContext] run_context unused
      def to_sql(run_context)
        "#{quote table_name}.#{quote column_name}#{display_name && " AS #{quote(display_name)}"}"
      end
    end
  end
end
