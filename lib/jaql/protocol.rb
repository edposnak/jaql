module Jaql
  module Protocol

    JSON_KEY = 'json'.freeze
    STR_KEY = 'str'.freeze
    FROM_KEY = 'from'.freeze

    WHERE_KEY = 'where'.freeze # TODO: Consider replacing injection-susceptible where with more constrained mongo-like syntax, e.g. $eq, $lt etc.
    ORDER_KEY = 'order'.freeze
    LIMIT_KEY = 'limit'.freeze
    OFFSET_KEY = 'offset'.freeze
    ASSOCIATION_SCOPE_OPTION_KEYS = [WHERE_KEY, ORDER_KEY, LIMIT_KEY, OFFSET_KEY]

  end
end