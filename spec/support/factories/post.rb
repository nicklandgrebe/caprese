FactoryGirl.define do
  factory :post do
    sequence(:title) { |n| "Post #{n}" }
    user

    trait :with_comments do
      transient do
        comment_count 2
      end

      after(:create) do |post, evaluator|
        create_list(:comment, evaluator.comment_count, post: post)
      end
    end
  end
end
