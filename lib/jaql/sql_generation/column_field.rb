module Jaql
  module SqlGeneration
    class ColumnField < Field
      attr_reader :table_name, :column_name
      private :table_name, :column_name

      def initialize(display_name, table_name, column_name)
        super(display_name)
        @table_name, @column_name = table_name, column_name
      end

      def to_sql
        "#{quote table_name}.#{quote column_name}#{as_display_name_sql}"
      end

      private

      def as_display_name_sql
        " #{super}" unless column_name == display_name # drop the AS when column name and display name are the same
      end
    end
  end
end
