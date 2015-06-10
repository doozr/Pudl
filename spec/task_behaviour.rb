require_relative './entity_behaviour'

shared_examples_for Pudl::BaseTask do

  it_behaves_like :attr_accessor, :after

  context "when the name is not a symbol" do
    let(:name) { "not a symbol" }
    let(:instance) { subject.new name }
    it "raises an error" do
      expect { instance }.to raise_error(ArgumentError)
    end
  end

end

shared_examples_for Pudl::BaseTask::Dsl do

  it_behaves_like :property_multi_static, :after

end
