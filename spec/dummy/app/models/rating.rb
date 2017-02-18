class Rating < ApplicationRecord
  belongs_to :comment

  validate :value_is_correct

  private

  def value_is_correct
    return if value

    errors.add(:value, :invalid, t: { custom_val: '123' })
  end
end
