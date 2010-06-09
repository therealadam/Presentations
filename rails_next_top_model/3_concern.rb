require 'common'
require 'active_support/concern'
require 'active_support/core_ext/class'
require 'active_support/inflector'
require 'active_support/cache'

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

class User
  include Cacheabilly

  attr_accessor :name

  cache_key(:friends, :friends_key) do
    %w{ Peter Egon Winston }
  end

  def friends_key
    "user-#{name}-friends"
  end

end

if __FILE__ == $0
  User.cache = ActiveSupport::Cache::MemCacheStore.new('localhost')
  user = User.new
  user.name = 'Ray'
  p user.friends
end
