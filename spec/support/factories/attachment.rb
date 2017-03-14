FactoryGirl.define do
  factory :attachment do
    sequence(:name) { |n| "Attachment #{n}" }
    post
  end

  factory :image do
    sequence(:name) { |n| "Image #{n}" }
    post
  end
end
