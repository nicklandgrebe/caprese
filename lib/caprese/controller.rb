require 'action_controller/api'
require 'caprese/concerns/versioning'
require 'caprese/controller/concerns/callbacks'
require 'caprese/controller/concerns/errors'
require 'caprese/controller/concerns/persistence'
require 'caprese/controller/concerns/query'
require 'caprese/controller/concerns/relationships'
require 'caprese/controller/concerns/rendering'
require 'caprese/controller/concerns/typing'

module Caprese
  class Controller < ActionController::API
    include ActiveSupport::Configurable
    include Callbacks
    include Errors
    include Persistence
    include Query
    include Relationships
    include Rendering
    include Typing
    include Versioning
    extend Versioning
  end
end
