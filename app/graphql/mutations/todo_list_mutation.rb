module Mutations
  TodoListMutation = GraphQL::ObjectType.define do
    name 'TodoListMutation'
    description 'Mutation type for todo list'

    field :create_todo_list, Types::TodoListType do
      argument :title, !types.String

      resolve ->(_obj, args, _ctx) do
        TodoList.create(
          title: args[:title]
        )
      end
    end

    field :edit_todo_list, Types::TodoListType do
      argument :id, !types.ID, 'the ID of the todolist to edit'
      argument :title, types.String, 'the new title'

      resolve ->(_obj, args, _ctx) do
        todo_list = TodoList.find_by(id: args[:id])

        if args.key?(:title)
          todo_list.update(
            title: args[:title]
          )
        end
        todo_list
      end
    end

    field :delete_todo_list, types[Types::TodoListType] do
      argument :id, !types.ID, 'the ID of the todolist to delete'

      resolve ->(_obj, args, _ctx) do
        todo_lists = TodoList.all
        todo_list = TodoList.find_by(id: args[:id])

        # Ensure that we find the todo list
        todo_list.destroy
         # return all todo lists
        todo_lists
      end
    end
  end
end
