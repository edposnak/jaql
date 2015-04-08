module Jaql

  class JSONString

    def initialize(json)
      raise "#[self.class} initialized with a #{json.class}" unless json.is_a?(String)
      @json = json
    end

    # specifying :json format makes Rails and Grape call #to_json on any object it gets back, including JSON
    # strings, so we just wrap the json in a JSONString that returns it when to_json is called
    # NB: this method ignores all args and returns the wrapped string as-is
    def to_json(*args)
      @json
    end

    def to_str
      @json
    end

    def to_s
      @json
    end

  end

end
