module Jaql
  module SqlGeneration
    # Allows for creation of fields from some association on some association, e.g. creator.last_name
    class AssociationAssociationField < AssociationField

      attr_reader :subquery2
      private :subquery2

      def initialize(display_name, subquery, subquery2)
        super(display_name, subquery)
        @subquery2 = subquery2
      end

      private

      def comment_sql
        qualified_name = association_chain.map(&:name).join('.')
        "-- #{qualified_name} #{from_comment}"
      end

      def projection_sql
        "SELECT #{subquery2.fields_sql}"
      end

      def subquery_chain
        [subquery, subquery2]
      end

    end
  end
end
