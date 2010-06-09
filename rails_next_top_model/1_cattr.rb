require 'common'
require 'active_support/inflector'
require 'active_support/cache'
require 'active_support/core_ext/class'

class User
  cattr_accessor :cache
  attr_accessor :name

  def friends
    cache.fetch("user-#{name}-friends") do
      %w{ Peter Egon Winston }
    end
  end

end

if __FILE__ == $0
  User.cache = ActiveSupport::Cache::MemCacheStore.new('localhost')
  user = User.new
  user.name = 'Ray'
  p user.friends
end
