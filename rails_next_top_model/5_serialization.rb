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
    names = %w{ Peter Ray Egon Winston }
    return if names.include?(record.name)
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

end

# >> u = User.new
# u = User.new
# => #<User:0x1031c4608>
# >> u.serializable_hash
# u.serializable_hash
# => {"name"=>nil, "degree"=>nil, "thought"=>nil}
# >> u.name = 'Ray Stanz'
# u.name = 'Ray Stanz'
# => "Ray Stanz"
# >> u.degree = 'Parapsychology'
# u.degree = 'Parapsychology'
# => "Parapsychology"
# >> u.thought = 'The Stay-Puft Marshmallow Man'
# u.thought = 'The Stay-Puft Marshmallow Man'
# => "The Stay-Puft Marshmallow Man"
# >> u.serializable_hash
# u.serializable_hash
# => {"name"=>"Ray Stanz", "degree"=>"Parapsychology", "thought"=>"The Stay-Puft Marshmallow Man"}
# >> u.to_json
# u.to_json
# => "{\"name\":\"Ray Stanz\",\"degree\":\"Parapsychology\",\"thought\":\"The Stay-Puft Marshmallow Man\"}"
# >> u.to_xml
# u.to_xml
# => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<user>\n  <degree>Parapsychology</degree>\n  <name>Ray Stanz</name>\n  <thought>The Stay-Puft Marshmallow Man</thought>\n</user>\n"
# >> json = u.to_json
# json = u.to_json
# => "{\"name\":\"Ray Stanz\",\"degree\":\"Parapsychology\",\"thought\":\"The Stay-Puft Marshmallow Man\"}"
# >> new_user = User.new
# new_user = User.new
# => #<User:0x103166378>
# >> new_user.from_json(json)
# new_user.from_json(json)
# => #<User:0x103166378 @name="Ray Stanz", @degree="Parapsychology", @thought="The Stay-Puft Marshmallow Man">
