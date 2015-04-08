module Jaql
  class ResolverFactory

    module FactoryMethods
      # @return [Model] model containing association resolver based on the given scope
      def resolver_for(scope)
        case scope.class.name

        when 'Sequel::Postgres::Dataset'
          if scope.respond_to?(:model) # Sequel::Postgres::Dataset with Sequel::Model
            sequel_model_resolver(scope.model)
          else # Sequel::Postgres::Dataset (no model)
            sequel_table_resolver(scope.first_source)
          end

        when 'ActiveRecord::Relation'
          active_record_model_resolver(scope.klass)

        else # could be a model instance
          if scope.class.ancestors.map(&:name).include?('Sequel::Model')
            sequel_model_resolver(scope.class)
          elsif scope.class.ancestors.map(&:name).include?('ActiveRecord::Base')
            active_record_model_resolver(scope.class)
          else
            fail "cannot determine resolver for scope with type '#{scope.class}'"
          end
        end
      end

      def runner_for(scope)
        case scope.class.name

        when 'Sequel::Postgres::Dataset'
          :sequel
        when 'ActiveRecord::Relation'
          :active_record

        else # could be a model instance
          if scope.class.ancestors.map(&:name).include?('Sequel::Model')
            :sequel
          elsif scope.class.ancestors.map(&:name).include?('ActiveRecord::Base')
            :active_record
          else
            fail "cannot determine runner for scope with type '#{scope.class}'"
          end
        end
      end

      private

      def active_record_model_resolver(orm_model_class)
        unless defined?(Mart::Reflection::ActiveRecordModel::Resolver)
          puts 'requiring mart/active_record_model_reflection ...'
          require 'mart/active_record_model_reflection'
        end
        Mart::Reflection::ActiveRecordModel::Resolver.new(orm_model_class)
      end

      def sequel_model_resolver(orm_model_class)
        unless defined?(Mart::Reflection::SequelModel::Resolver)
          puts 'requiring mart/sequel_model_reflection ...'
          require 'mart/sequel_model_reflection'
        end

        Mart::Reflection::SequelModel::Resolver.new(orm_model_class)
      end

      def sequel_table_resolver(table_name)
        unless defined?(Mart::Reflection::SequelTable::Resolver)
          puts 'requiring mart/sequel_table_reflection ...'
          require 'mart/sequel_table_reflection'
        end

        Mart::Reflection::SequelTable::Resolver.new(table_name)
      end

    end
    extend FactoryMethods

  end
end
