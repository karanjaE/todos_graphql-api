module Mutations
  ItemMutation = GraphQL::ObjectType.define do
    name 'ItemMutation'
    description 'Mutations for items'

    field :create_item, Types::ItemType do
      argument :todo_list_id, !types.ID
      argument :name, !types.String

      resolve ->(_obj, args, _ctx) do
        todo_list = TodoList.find(args[:todo_list_id])

        return unless todo_list

        todo_list.items.create(
          name: args[:name]
        )
      end
    end

    field :mark_item_done, Types::ItemType do
      argument :id, !types.ID

      resolve ->(_obj, args, _ctx) do
        item = Item.find_by(id: args[:id])
        return unless item

        item.update(
          done: true
        )

        item
      end
    end

    field :delete_item, Types::ItemType do
      argument :id, !types.ID

      resolve ->(_obj, args, _ctx) do
        item = Item.find_by(id: args[:id])
        return unless item

        item.destroy
      end
    end
  end
end
