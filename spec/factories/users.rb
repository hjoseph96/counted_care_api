FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    name { "Test User" }
    
    trait :with_google_oauth do
      provider { "google_oauth2" }
      uid { "google_uid_123" }
    end
  end
end
