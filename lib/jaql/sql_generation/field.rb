module Jaql
  module SqlGeneration

    class Field
      abstract_method :to_sql

      private

      def quote(id)
        "\"#{id}\""
      end
    end

  end
end
