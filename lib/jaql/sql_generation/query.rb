module Jaql
  module SqlGeneration
    class Query

      attr_reader :resolver, :spec
      private :resolver, :spec

      def initialize(resolver, spec=nil)
        @resolver = resolver

        # TODO deep stringify keys when spec is a hash
        hash_spec = spec.is_a?(String) ? JSON.parse(spec) : spec || {}
        validate!(hash_spec)
        @spec = hash_spec
      end

      def fields_sql(run_context)
        return "#{table_name}.*" if fields.empty?
        fields.map {|field| field.to_sql(run_context)}.join(",\n")
      end

      private

      def validate!(spec)
        spec.keys.all? {|k| k.is_a?(String)} or raise "spec containing non-string keys passed to #{self.class}.new. Currently spec must be a JSON hash"
      end

      def table_name
        @table_name ||= resolver.table_name
      end

      def column_or_association(real_name, display_name=nil, subquery_spec=nil)
        if column_name = resolver.column_for(real_name)
          ColumnField.new(table_name, column_name, display_name)
        elsif association = resolver.association_for(real_name)
          new_resolver = resolver.build_from_association(association)
          subquery = Query.new(new_resolver, subquery_spec)
          AssociationField.new(association, display_name, subquery)
        else
          puts "unknown #{table_name}.#{real_name}"
          UnknownField.new(real_name, display_name, subquery)
        end
      end

      def fields
        @fields ||= parse_fields
      end

      # Protocol
      JSON_KEY = 'json'.freeze
      FROM_KEY = 'from'.freeze

      # parses a spec into a list of Fields, each of which may contain their own lists of fields
      def parse_fields
        result = []

        # TODO allow
        #   topics: { } # without from or json
        #   members: { from: :users } # without json
        if json = spec[JSON_KEY]
          json.each do |field|
            case field
            when String, Symbol
              result << column_or_association(field)
            when Hash
              field.each do |display_name, subquery_or_real_name|
                case subquery_or_real_name
                when String, Symbol
                  real_name = subquery_or_real_name
                  result << column_or_association(real_name, display_name)
                when Hash
                  subquery = subquery_or_real_name
                  # peek into the subquery to get the real association name if different from display name
                  real_name = subquery[FROM_KEY] || display_name
                  result << column_or_association(real_name, display_name, subquery)
                end
              end
            else # TODO raise invalid query
              puts "UNKNOWN: '#{field}'"
            end
          end
        end

        result
      end

    end
  end

end
