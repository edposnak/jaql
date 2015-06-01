module Jaql
  module SqlGeneration

    class Field
      abstract_method :to_sql

      attr_reader :display_name
      private :display_name

      def initialize(display_name)
        @display_name = display_name
      end

      private

      def quote(id)
        already_quoted?(id) ? id : "\"#{id}\""
      end

      def already_quoted?(id)
        id =~ /^".*"$/
      end
    end

  end
end
