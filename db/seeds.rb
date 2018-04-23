# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'faker'

20.times do
  TodoList.create(
    title: Faker::Lorem.word
  )
end

lists = TodoList.all

lists.each do |list|
  5.times do
    list.items.create(
      name: Faker::Lorem.word,
      done: [true, false].sample
    )
  end
end
