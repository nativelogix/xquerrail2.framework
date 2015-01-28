#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the private variables in deploy/lib/server_config.rb
#
# any public method you create here can be called from the command line. See
# the examples below for more information.
#
class ServerConfig

  #
  # You can easily "override" existing methods with your own implementations.
  # In ruby this is called monkey patching
  #
  # first you would rename the original method
  # alias_method :original_deploy_modules, :deploy_modules

  # then you would define your new method
  # def deploy_modules
  #   # do your stuff here
  #   # ...

  #   # you can optionally call the original
  #   original_deploy_modules
  # end

  #
  # you can define your own methods and call them from the command line
  # just like other roxy commands
  # ml local my_custom_method
  #
  # def my_custom_method()
  #   # since we are monkey patching we have access to the private methods
  #   # in ServerConfig
  #   @logger.info(@properties["ml.content-db"])
  # end

  #
  # to create a method that doesn't require an environment (local, prod, etc)
  # you woudl define a class method
  # ml my_static_method
  #
  # def self.my_static_method()
  #   # This method is static and thus cannot access private variables
  #   # but it can be called without an environment
  # end

  # Apply mode change for the given XQuerrail domain model.
  def apply_xquerrail_changes
    count=0
    modulesRoot = @properties["ml.xquerrail.dir"]
    properties = {}
    properties[:app_name] = @properties["ml.app-server-name"]
    model = @properties["ml.model"]
    xqueryPath = "#{modulesRoot}/main/_framework/roxy/applyXQuerrailChanges.xqy"
    xqueryFile = File.read(File.expand_path(xqueryPath, __FILE__))
    logger.info "Apply XQuerrail Changes to #{model} model..."
    r = execute_query %Q{#{xqueryFile} xq:apply-xquerrail-changes("#{model}")}, properties
    if(r.body.length==0)
      count=count+1
    end
    logger.info "Apply XQuerrail changes done."
  end

  def refresh_cache_xquerrail
    logger.info "Refresh XQuerrail Caches..."
    r = go %Q{http://#{@hostname}:#{@properties["ml.app-port"]}/initialize.xqy}, "get"
    if r.code.to_i != 200
      logger.error "#{r.body}"
    end
  end

end
