module Jaql
  module SqlGeneration
    class AssociationField < Field
      include AssociationSQL

      attr_reader :association, :display_name, :subquery
      private :association, :display_name, :subquery

      def initialize(association, display_name=nil, subquery=nil)
        @association  = association
        @display_name = display_name
        @subquery     = subquery
      end

      def to_sql
        comment_sql = "-- #{association.type} #{association.name} (#{association.associated_table})"

        cte = "#{select_sql}\n #{from_sql}\n #{scope_sql}"
        return_type = association.to_one? ? Query::ROW_RETURN_TYPE : Query::ARRAY_RETURN_TYPE
        field_sql = subquery.json_sql(cte, display_name || association.name, return_type)

        [comment_sql, field_sql].join("\n")
      end

      private


    end
  end
end
