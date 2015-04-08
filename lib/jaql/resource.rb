module Jaql
  class Resource
    attr_reader :scope
    private :scope

    class NotFoundError < StandardError
    end

    # TODO infer table from string/symbol, e.g. Jaql.resource(:users).show(params[:query])

    # @param [Hash] options
    # @param [Object] scope defines the scope to search
    def initialize(scope, options={})
      # scope can be an ActiveRecord::Relation, table name, Sequel dataset, AR or Sequel model instance, ...
      @scope = scope
    end

    def index(query_spec={})
      JSONString.new runnable_query(query_spec).json_array
    end

    def show(query_spec={})
      JSONString.new runnable_query(query_spec).json_row
    end

    private

    def runnable_query(query_spec)
      SqlGeneration::RunnableQuery.new(scope, query_spec)
    end

  end
end
