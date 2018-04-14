module QueryTypes
  TodoListQueryType = GraphQL::ObjectType.define do
    name 'TodoListQueryType'
    description 'The todo list query type'

    field :todo_lists, types[Types::TodoListType], 'returns all todo lists' do
      resolve ->(_obj, _args, _ctx) { TodoList.all }
    end
  end
end
