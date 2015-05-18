require 'abstract_method'

require 'dart' # just brings in core, other resolvers brought in dynamically as needed

require 'jaql/version'
require 'jaql/protocol'

require 'jaql/sql_generation'

require 'jaql/json_string'
require 'jaql/resource'


module Jaql

  module_function

  def resource(scope, options={})
    Resource.new(scope, options)
  end

end
