# Credits go to original author [1]
# [1] https://gist.github.com/avdi/1051967
class Hash
  # h = {
  #   :foo => {
  #     :bar => [:x, :y, :z],
  #     :baz => Hash.new{ "missing value in :bar" }
  #   }
  # }
  #
  # h.deep_fetch(:foo, :bar, 0)     # => :x
  # h.deep_fetch(:buz) { :default_value } # => :default_value
  # h.deep_fetch(:foo, :bar, 5) { :default_value } # => :default_value
  def deep_fetch(*keys, &fetch_default)
    throw_fetch_default = fetch_default && lambda {|key, coll|
      args = [key, coll]
      # only provide extra block args if requested
      args = args.slice(0, fetch_default.arity) if fetch_default.arity >= 0
      # If we need the default, we need to stop processing the loop immediately
      throw :df_value, fetch_default.call(*args)
    }
    catch(:df_value){
      keys.inject(self){|value,key|
        block = throw_fetch_default && lambda{|*args|
          # sneak the current collection in as an extra block arg
          args << value
          throw_fetch_default.call(*args)
        }
        value.fetch(key, &block)
      }
    }
  end

  # return exception on not found
  # h.deep_fetch!(:buz)             # => KeyError
  def deep_fetch!(*keys)
    e = lambda{|*args|
      raise KeyError, "Key #{args} does not exist"
    }
    case keys.size
    when 1 then fetch(keys, e.call(keys) )
    else deep_fetch(*keys){ e.call(keys) }
    end
  end

  # Overload [] to work with multiple keys
  # h[:foo]                         # => {:baz=>{}, :bar=>[:x, :y, :z]}
  # h[:foo, :bar]                   # => [:x, :y, :z]
  # h[:foo, :bar, 1]                # => :y
  # h[:foo, :bar, 5]                # => nil
  # h[:foo, :baz]                   # => {}
  # h[:foo, :baz, :fuz]             # => "missing value in :bar"
  def [](*keys)
    case keys.size
    when 1 then fetch(keys, nil)
    else deep_fetch(*keys){|key, coll| coll[key]}
    end
  end
end
