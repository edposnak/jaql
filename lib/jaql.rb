require 'abstract_method'

require 'mart' # TODO need to determine here whether we are doing Sequel or ActiveRecord

require 'jaql/version'

require 'jaql/sql_generation'
require 'jaql/resolver_factory'

require 'jaql/json_string'
require 'jaql/resource'


module Jaql

  module_function

  def resource(scope, options={})
    Resource.new(scope, options)
  end

end
