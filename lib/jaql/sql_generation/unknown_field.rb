module Jaql
  module SqlGeneration
    class UnknownField < Field
      attr_reader :association, :display_name, :subquery
      private :association, :display_name, :subquery

      def initialize(association, display_name=nil, subquery=nil)
        @association  = association
        @display_name = display_name
        @subquery     = subquery
      end

      def to_sql
        raise "unknown column or association '#{real_name}' (#{real_name.class})"
      end
    end
  end
end

