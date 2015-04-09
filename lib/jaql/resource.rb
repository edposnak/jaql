module Jaql
  # Resource wraps a scope, which can be an ActiveRecord::Relation, Sequel dataset, table name, ORM model instance, etc.
  # It provides index and show methods that produce JSON for the scope.
  class Resource
    attr_reader :scope
    private :scope

    class NotFoundError < StandardError
    end

    # TODO infer table from string/symbol, e.g. Jaql.resource(:users).show(params[:query])

    # @param [Hash] options
    # @param [Object] scope defines the scope to search
    def initialize(scope, options={})
      @scope = scope
    end

    def index(query_spec={})
      JSONString.new SqlGeneration::RunnableQuery.for(scope, query_spec).json_array
    end

    def show(query_spec={})
      JSONString.new SqlGeneration::RunnableQuery.for(scope, query_spec).json_row
    end

  end
end
