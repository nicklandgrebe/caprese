FactoryGirl.define do
  factory :rating do
    sequence(:value) { |n| n }
    comment
  end
end
