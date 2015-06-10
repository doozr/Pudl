shared_examples_for :attr_accessor do |attribute|

  it "reads assigned values" do
    instance.send :"#{attribute}=", "value"
    expect(instance.send attribute).to eq("value")
  end

end

