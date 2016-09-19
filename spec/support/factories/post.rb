FactoryGirl.define do
  factory :post do
    sequence(:title) { |n| "Post #{n}" }
    user

    trait :with_comments do
      after_create do |post|
        create_list(:comment, 2, post: post)
      end
    end
  end
end
