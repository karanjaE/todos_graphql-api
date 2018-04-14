module Types
  TodoListType = GraphQL::ObjectType.define do
    name 'TodoListType'
    description 'The Todo List type'

    field :id, !types.ID
    field :title, !types.String
    field :items, types[Types::ItemType] do
      resolve ->(obj, _args, _ctx) { obj.items }
    end
  end
end
