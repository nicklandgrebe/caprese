class Rating < ApplicationRecord
  belongs_to :comment

  validates_presence_of :value
end
