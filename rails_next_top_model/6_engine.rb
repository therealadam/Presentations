require 'common'
require 'active_support/concern'
require 'active_support/core_ext/class'
require 'active_support/inflector'
require 'active_support/cache'
require 'active_model'
require 'arel'

module Cacheabilly
  extend ActiveSupport::Concern

  included do
    cattr_accessor :cache

    cattr_accessor :cache_lookups, :cache_keys do
      {}
    end

    def self.cache_key(name, key, &block)
      cache_lookups[name] = block
      cache_keys[name] = key

      class_eval %Q{

        def #{name}
          return @#{name} if @#{name}.present?
          key = method(cache_keys[:#{name}]).call
          @#{name} = cache.fetch(key) do
            block.call
          end
        end
       }
    end
  end
end

class GhostbusterValidator < ActiveModel::Validator

  def validate(record)
    return if %w{ Peter Ray Egon Winston }.include?(record.name)
    record.errors[:base] << "Not a Ghostbuster :("
  end

end

class User
  include Cacheabilly

  attr_accessor :name

  cache_key(:friends, :friends_key) do
    %w{ Peter Egon Winston }
  end

  def friends_key
    "user-#{name}-friends"
  end

  include ActiveModel::Validations

  validates_presence_of :name
  validates_length_of :name, :minimum => 3, :message => 'Names with less than 3 characters are dumb'
  validates_with GhostbusterValidator

  include ActiveModel::Serialization

  attr_accessor :degree, :thought

  def attributes
    @attributes ||= {'name' => name, 'degree' => degree, 'thought' => thought}
  end

  def attributes=(hash)
    self.name = hash['name']
    self.degree = hash['degree']
    self.thought = hash['thought']
  end

  include ActiveModel::Serializers::JSON
  include ActiveModel::Serializers::Xml

  include Arel::Relation

  cattr_accessor :engine

  # Our engine uses this method to infer the record's key
  def cache_key
    "user-#{name.downcase.gsub(' ', '_')}"
  end

  def marshal_dump
    attributes
  end

  def marshal_load(hash)
    self.attributes = hash
  end

  def save
    # HAX: use dirty tracking to call insert or update here
    insert(self)
  end

  def find(name)
    key = name.downcase.gsub(' ', '_')
    where("user-#{key}").call
  end

end

class UserEngine

  attr_reader :cache

  def initialize(cache)
    @cache = cache
  end

  def create(insert)
    record = insert.relation
    key = record.cache_key
    value = record # Note: this uses Marshal, b/c to_json w/ arel is buggy
    cache.write(key, value)
  end

  # Ignores chained queries, i.e. take(n).where(...)
  def read(select)
    raise ArgumentError.new("#{select.class} not supported") unless select.is_a?(Arel::Where)
    key = select.predicates.first.value
    cache.read(key)
  end

  def update(update)
    p update
    record = update.assignments.value
    key = record.cache_key
    value = record # Note: this uses Marshal, b/c to_json w/ arel is buggy
    cache.write(key, value)
  end

  def delete(delete)
    key = delete.relation.cache_key
    cache.delete(key)
  end

end

User.cache = ActiveSupport::Cache::MemCacheStore.new('localhost')
User.engine = UserEngine.new(User.cache)
