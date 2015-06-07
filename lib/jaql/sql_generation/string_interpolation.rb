module Jaql
  module SqlGeneration

    module StringInterpolation

      def str_sql_for(str, table_name)
        clauses = []
        els = str.split /(\#{.*?})/
        els.each_slice(2) do |literal, interpolated|
          clauses << "'#{literal}'" unless literal.blank?
          clauses << "#{quote table_name}.#{quote str_interp(interpolated)}" unless interpolated.blank?
        end

        "#{clauses.join(' || ')} #{as_display_name_sql}"
      end

      # remove the outer #{} from a matched interpolation
      def str_interp(interpolated_string)
        md = /\#{(.*?)}/.match(interpolated_string)
        # ASSUMPTION: the interpolate_string contains at most one interpolation
        md.captures.first
      end

    end

  end
end
