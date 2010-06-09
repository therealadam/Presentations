require 'common'
require 'active_support/core_ext/class'
require 'active_support/inflector'
require 'active_support/cache'

class User
  cattr_accessor :cache
  attr_accessor :name

  cattr_accessor :cache_lookups, :cache_keys do
    {}
  end

  def self.cache_key(name, key, &block)
    class_eval %Q{
      cache_lookups[name] = block
      cache_keys[name] = key

      def #{name}
        return @#{name} if @#{name}.present?
        key = method(cache_keys[:#{name}]).call
        @#{name} = cache.fetch(key) do
          block.call
        end
      end
    }
  end

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
