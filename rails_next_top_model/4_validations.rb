require 'common'
require 'active_support/concern'
require 'active_support/core_ext/class'
require 'active_support/inflector'
require 'active_support/cache'
require 'active_model'

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

end

# >> u = User.new
# u = User.new
# => #<User:0x103a56f28>
# >> u.valid?
# u.valid?
# => false
# >> u.errors
# u.errors
# => #<OrderedHash {:base=>["Not a Ghostbuster :("], :name=>["can't be blank", "can't be blank", "Names with less than 3 characters are dumb", "can't be blank", "Names with less than 3 characters are dumb"]}>
# >> u.name = 'Ron'
# u.name = 'Ron'
# => "Ron"
# >> u.valid?
# u.valid?
# => false
# >> u.errors
# u.errors
# => #<OrderedHash {:base=>["Not a Ghostbuster :("]}>
# >> u.name = 'Ray'
# u.name = 'Ray'
# => "Ray"
# >> u.valid?
# u.valid?
# => true
