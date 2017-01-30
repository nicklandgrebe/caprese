class ApplicationRecord < ActiveRecord::Base
  include Caprese::Record

  self.abstract_class = true
end
