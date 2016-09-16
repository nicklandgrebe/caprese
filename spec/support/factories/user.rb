FactoryGirl.define do
  factory :user do
    sequence(:name) { |n| "Rick#{n.ordinalize} Bobby" }

    trait :with_posts do
      after_create do |user|
        create :post, user: user
        create :post, :with_comments, user: user
      end
    end
  end
end
