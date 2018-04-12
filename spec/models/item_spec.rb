RSpec.describe Item, type: :model do
  it 'has a valid factory' do
    expect(build(:item)).to be_valid
  end

  let(:todo_list) { create(:todo_list) }
  let(:attributes) do
    {
      name: 'A test item',
      done: false,
      todo_list: todo_list
    }
  end

  let(:item) { create(:item, **attributes) }

  describe 'model validations' do
    # check that the fields received the right values
    it { expect(item).to allow_value(attributes[:name]).for(:name) }
    it { expect(item).to allow_value(attributes[:done]).for(:done) }
    # ensure that the title field is never empty
    it { expect(item).to validate_presence_of(:name) }
    # ensure that the name is unique for each item
    it { expect(item).to validate_uniqueness_of(:name)}
  end

  describe 'model associations' do
    it { expect(item).to belong_to(:todo_list) }
  end
end
