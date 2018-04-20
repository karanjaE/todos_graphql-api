RSpec.describe QueryTypes::TodoListQueryType do
  # avail type definer in our tests
  types = GraphQL::Define::TypeDefiner.instance

  # create fake todo lists using the todo_list factory
  let!(:list1) { create(:todo_list) }
  let!(:list2) { create(:todo_list) }
  let!(:list3) { create(:todo_list) }

  describe 'querying all todo lists' do

    it 'has a :todo_lists that returns a ToDoList type' do
      expect(subject).to have_field(:todo_lists).that_returns(types[Types::TodoListType])
    end

    it 'returns all our created todo lists' do
      query_result = subject.fields['todo_lists'].resolve(nil, nil, nil)

      todo_lists = [list1, list2, list3]

      # ensure that each of our todo lists is returned
      todo_lists.each do |list|
        expect(query_result.to_a).to include(list)
      end

      # we can also check that the number of lists returned is the one we created.
      expect(query_result.count).to eq(todo_lists.count)
    end
  end

  describe 'querying a specific todo_list using it\'s id' do
    it 'returns the queried todo list' do
      # set the id of list1 as the ID
      id = list1.id
      args = { id: id }
      query_result = subject.fields['todo_list'].resolve(nil, args, nil)

      # we should only get the first todo list from the db.
      expect(query_result).to eq(list1)
    end
  end
end
