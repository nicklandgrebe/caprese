FactoryGirl.define do
  factory :comment do
    sequence(:body) { |n| "This is the #{n.ordinalize} comment" }
    post
    user

    trait :with_rating do
      after(:create) do |comment|
        create :rating, comment: comment
      end
    end
  end
end
