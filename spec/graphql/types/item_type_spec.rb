RSpec.describe Types::ItemType do
  # avail type definer in our tests
  types = GraphQL::Define::TypeDefiner.instance

  it 'has an :id field of ID type' do
    # Ensure that the field id is of type ID
    expect(subject).to have_field(:id).that_returns(!types.ID)
  end

  it 'has a :name field of String type' do
    # Ensure the field is of String type
    expect(subject).to have_field(:name).that_returns(!types.String)
  end

  it 'has a :done field of Boolean type' do
    # Ensure the field is of Boolean type
    expect(subject).to have_field(:done).that_returns(types.Boolean)
  end
end
