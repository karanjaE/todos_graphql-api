RSpec.describe 'QueryTypes::TodoListQueryType' do

  # create a todo lost to which each item will belong
  let!(:list1) { create(:todo_list) }
  let!(:list2) { create(:todo_list) }

  let!(:item1) { create(:item, todo_list: list1) }
  let!(:item2) { create(:item, todo_list: list1) }
  let!(:item3) { create(:item, todo_list: list1) }
  let!(:item4) { create(:item, todo_list: list2) }

  describe 'querying for todo lists with an item field included' do
    it 'returns an array of items for each field' do
      query_result = QueryTypes::TodoListQueryType.fields['todo_lists'].resolve(nil, nil, nil)

       todo_list1 = query_result[0]
       todo_list2 = query_result[1]

       item_list1 = [item1, item2, item2]

       item_list1.each do |item|
         expect(todo_list1.items).to include(item)
       end
       expect(todo_list1.items.count).to eq(item_list1.count)
       expect(todo_list2.items).to include(item4)

       expect(todo_list2.items).not_to include(item2)
    end
  end
end
