FactoryGirl.define do
  factory :comment do
    sequence(:body) { |n| "This is the #{n.ordinalize} comment" }
    post
    rating
    user
  end
end
