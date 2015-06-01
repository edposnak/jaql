module Jaql
  module SqlGeneration
    class InterpolatedStringField < Field
      include StringInterpolation

      attr_reader :display_name, :table_name, :interpolated_string
      private :display_name, :table_name, :interpolated_string

      def initialize(display_name, table_name, interpolated_string)
        @table_name = table_name
        @interpolated_string = interpolated_string
        @display_name = display_name
      end

      def to_sql
        str_sql_for(interpolated_string, table_name)
      end

    end
  end
end
