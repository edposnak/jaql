module Jaql
  module SqlGeneration
    module RunnableQueryFactoryMethods
      def for(scope, query_spec)
        scope_class = scope.class

        case scope_class.name

        when 'Sequel::Postgres::Dataset'
          if scope.respond_to?(:model) # Sequel::Postgres::Dataset with Sequel::Model
            sequel_model_query(scope, query_spec, scope.model)
          else # Sequel::Postgres::Dataset (no model)
            sequel_table_query(scope, query_spec, scope.first_source)
          end

        when 'ActiveRecord::Relation'
          active_record_model_query(scope, query_spec, scope.klass)

        else # could be an ORM model instance
          if scope_class.ancestors.map(&:name).include?('Sequel::Model')
            sequel_model_query(scope, query_spec, scope_class)
          elsif scope_class.ancestors.map(&:name).include?('ActiveRecord::Base')
            active_record_model_query(scope, query_spec, scope_class)
          else
            fail "cannot determine resolver for scope with type '#{scope_class}'"
          end
        end
      end

      private

      def active_record_model_query(scope, query_spec, model)
        unless defined?(Dart::Reflection::ActiveRecordModel::Resolver)
          require 'dart/active_record_model_reflection'
        end
        resolver = Dart::Reflection::ActiveRecordModel::Resolver.new(model)
        ActiveRecordQuery.new(scope, query_spec, resolver)
      end

      def sequel_table_query(scope, query_spec, table)
        unless defined?(Dart::Reflection::SequelTable::Resolver)
          require 'dart/sequel_table_reflection'
        end
        resolver = Dart::Reflection::SequelTable::Resolver.new(table)
        SequelQuery.new(scope, query_spec, resolver)
      end

      def sequel_model_query(scope, query_spec, model)
        unless defined?(Dart::Reflection::SequelModel::Resolver)
          require 'dart/sequel_model_reflection'
        end
        resolver = Dart::Reflection::SequelModel::Resolver.new(model)
        SequelQuery.new(scope, query_spec, resolver)
      end

    end
  end
end
