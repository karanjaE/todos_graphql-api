FactoryBot.define do
  factory :item do
    sequence(:name) { |n| "Item name #{n}"}
    done false

    todo_list
  end
end
