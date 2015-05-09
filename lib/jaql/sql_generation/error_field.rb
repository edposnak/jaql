module Jaql
  module SqlGeneration
    class ErrorField < Field
      attr_reader :message

      def initialize(message)
        @message = message
      end

      def to_sql
        raise message
      end
    end
  end
end

