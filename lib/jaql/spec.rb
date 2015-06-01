module Jaql
  class Spec

    include Jaql::Protocol

    attr_reader :spec
    private :spec

    def initialize(raw_spec=nil)
      # hash_spec = raw_spec.is_a?(String) ? JSON.parse(raw_spec) : raw_spec.to_h
      # Sadly, Hash#to_h and NilClass#to_h are not available in ruby 1.9.3 so we have to do case analysis
      hash_spec = case raw_spec
                  when String
                    JSON.parse(raw_spec)
                  when Hash
                    raw_spec
                  when NilClass
                    {}
                  else
                    raw_spec.to_h
                  end


      # TODO deep stringify keys when raw_spec is a hash (JSON generate/decode might be equally fast)
      hash_spec.keys.all? {|k| k.is_a?(String)} or raise "a hash spec containing non-string keys was passed to #{self.class}.new. Currently spec must be a JSON hash"

      @spec = hash_spec.freeze
    end

    # Returns a frozen hash with the values of this Spec
    def to_h
      spec
    end

    def to_s
      spec.to_s
    end

    # If field_spec contains a FROM_KEY with a '.' in it then it refers to an association column or function
    # Examples
    #   owner_name: {from: 'owner.name' }
    def association_column_or_function?
      from && from.include?('.')
    end

    def from
      @from ||= spec[FROM_KEY]
    end

    def str
      @str ||= spec[STR_KEY]
    end

    def json
      @json ||= spec[JSON_KEY]
    end

    def association_and_column_or_function
      from.split('.')
    end

    def scope_options
      spec.slice(*ASSOCIATION_SCOPE_OPTION_KEYS)
    end

    # methods to determine type of spec
    # TODO consider implementing a type method

    # If field_spec contains a FROM_KEY without a '.' and it has a STR_KEY then it refers to an association str
    # Examples
    #   owner_name: { from: owner, str: "#{first_name} #{last_name}" }
    def association_str?
      from && str
    end

    # If field_spec contains a FROM_KEY without a '.' and no STR_KEY then it refers to an aliased association or column
    # Examples
    #   topics: {from: 'assigned_topics'}
    #   last: {from: 'last_name'}
    def aliased_column_or_association?
      from && str.nil?
    end

    # If field_spec has no FROM_KEY but it has a STR_KEY then it refers to a str
    # Examples
    #   name: {str: '#{first_name} #{last_name}'}
    def aliased_str?
      str && from.nil?
    end

    # If field_spec has no FROM_KEY and no STR_KEY then it refers to a non-aliased column or association
    # Examples
    #   users: { json: [:id, :name]}
    #   start_time: {}
    def non_aliased_column_or_association?
      from.nil? && str.nil?
    end

  end
end