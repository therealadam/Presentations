require 'common'
require 'active_support/inflector'
require 'active_support/cache'

class User

  attr_accessor :name

  def friends
    cache.fetch("user-#{name}-friends") do
      %w{ Peter Egon Winston }
    end
  end

  protected

  def cache
    ActiveSupport::Cache::MemCacheStore.new
  end

end

if __FILE__ == $0
  user = User.new
  user.name = 'Ray'
  p user.friends
end
