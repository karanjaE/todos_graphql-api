RSpec.describe Mutations::TodoListMutation do
  describe 'creating a new record' do
    let(:args) do
      {
        title: 'Some random title'
      }
    end

    it 'increases todo lists by 1' do
      subject.fields['create_todo_list'].resolve(nil, args, nil)
      # adds one todo_list to the db
      expect(TodoList.count).to eq 1
    end
  end

  describe 'editing a todo list' do
    let!(:todo_list) { create(:todo_list, title: 'Old title') }

    it 'updates a todo list' do
      args = {
        id: todo_list.id,
        title: 'I am a new todo_list title'
      }

      query_result = Mutations::TodoListMutation.fields['edit_todo_list'].resolve(nil, args, nil)

      expect(query_result.title).to eq(args[:title])
      # test that the number of todo lists doesn't change
      expect(TodoList.count).to eq 1
    end
  end

  describe 'deleting a todo list' do
    let!(:todo_list1) { create(:todo_list) }
    let!(:todo_list2) { create(:todo_list) }

    it 'deletes a todo list' do
      args = {
        id: todo_list1.id
      }
      query = subject.fields['delete_todo_list'].resolve(nil, args, nil)

      expect(query).not_to include(todo_list1)
    end

    it 'reduces the number of todo lists by one' do
      args = {
        id: todo_list1.id
      }
      subject.fields['delete_todo_list'].resolve(nil, args, nil)

      expect(TodoList.count).to eq 1
    end
  end
end
