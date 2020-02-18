require 'action_controller'
require 'caprese/concerns/url_helpers'
require 'caprese/concerns/versioning'
require 'caprese/controller/concerns/aliasing'
require 'caprese/controller/concerns/callbacks'
require 'caprese/controller/concerns/errors'
require 'caprese/controller/concerns/persistence'
require 'caprese/controller/concerns/query'
require 'caprese/controller/concerns/relationships'
require 'caprese/controller/concerns/rendering'
require 'caprese/controller/concerns/typing'

module Caprese
  class Controller < ActionController::API
    include Aliasing
    include Callbacks
    # FIXME: Be careful about including `Errors` in certain order, because it has `rescue_from Exception` and this affects
    #   control flow with other rescue handlers if included after their modules
    include Errors
    include Persistence
    include Query
    include Relationships
    include Rendering
    include Typing
    include UrlHelpers
    include Versioning
    extend UrlHelpers
    extend Versioning
  end
end
