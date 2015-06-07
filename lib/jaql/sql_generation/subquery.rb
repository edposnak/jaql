module Jaql
  module SqlGeneration
    class Subquery < Query

      attr_reader :association # public

      # @param [Context] run_context
      # @param [Spec] jaql_spec
      # @param [Dart::Association] association
      def initialize(run_context, jaql_spec, association)
        super(run_context, jaql_spec, association.resolver)

        # TODO alias any join tables in the association that are the same as resolver.table_name
        # table_alias = "#{association.associated_table}_#{run_context.tmp_relation_name}" # if association.associated_table == resolver.table_name
        @association = association
      end
    end
  end

end
