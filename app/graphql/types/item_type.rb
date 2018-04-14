module Types
  ItemType = GraphQL::ObjectType.define do
    name 'ItemType'
    description 'Type definition for items'

    field :id, !types.ID
    field :name, !types.String
    field :done, types.Boolean
  end
end
