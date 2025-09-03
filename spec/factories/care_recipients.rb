FactoryBot.define do
  factory :care_recipient do
    name { "John Doe" }
    relationship { "Father" }
    insurance_info { "Blue Cross Blue Shield" }
    conditions { ["Diabetes", "Hypertension"] }
    association :user
  end
end
