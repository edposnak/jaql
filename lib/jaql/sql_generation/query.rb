module Jaql
  module SqlGeneration
    class Query

      include QueryParsing
      attr_reader :run_context, :spec, :resolver
      private :run_context, :spec, :resolver

      def initialize(run_context, spec, resolver)
        @run_context = run_context or fail "#{self.class} must be initialized with a run_context"
        @resolver = resolver or fail "#{self.class} must be initialized with a resolver"

        # TODO deep stringify keys when spec is a hash
        hash_spec = spec.is_a?(String) ? JSON.parse(spec) : spec || {}
        validate!(hash_spec)
        @spec = hash_spec
      end

      ARRAY_RETURN_TYPE = :array
      ROW_RETURN_TYPE = :row

      def json_sql(cte, display_name, return_type)
        display_name or raise "display_name cannot be blank"

        rel = run_context.tmp_relation_name
        select_sql = case return_type
                     when ARRAY_RETURN_TYPE
                       "coalesce(json_agg(#{rel}), '[]'::JSON)"
                     when ROW_RETURN_TYPE
                       "row_to_json(#{rel})"
                       # uncomment this to return {} instead of nil for empty rows
                       # "coalesce(row_to_json(#{rel}), '{}'::JSON)"
                     else
                       fail "unknown return type: '#{return_type}'"
                     end

        %Q{( SELECT #{select_sql} AS "#{display_name}" FROM (#{cte}) #{rel} )}
      end

      def json_array_sql(cte, display_name)
        json_sql(cte, display_name, ARRAY_RETURN_TYPE)
      end

      def json_row_sql(cte, display_name)
        json_sql(cte, display_name, ROW_RETURN_TYPE)
      end

      def fields_sql
        return "#{resolver.table_name}.*" if fields.empty?

        fields.map {|field| field.to_sql}.join(",\n")
      end

      private

      def validate!(spec)
        spec.keys.all? {|k| k.is_a?(String)} or raise "spec containing non-string keys passed to #{self.class}.new. Currently spec must be a JSON hash"
      end

      def fields
        @fields ||= parse_fields
      end

    end
  end

end