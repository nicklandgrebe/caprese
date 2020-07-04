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

    trait :with_replies do
      after(:create) do |comment|
        create :comment, parent_comment: comment, post: comment.post
      end
    end
  end
end
