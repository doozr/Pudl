require_relative './property_behaviour'
require_relative './attr_behaviour'

shared_examples_for Pudl::Entity do

  describe "#only_if" do
    it_behaves_like :attr_accessor, :only_if
  end

  describe "#name" do
    it "returns the element name" do
      expect(instance.name).to eq(name)
    end
  end

end

shared_examples_for Pudl::Entity::Dsl do
  describe "#only_if" do
    it_behaves_like :property_single, :only_if
  end
end

shared_examples_for Pudl::Entity::Runner do
  let(:runner) { instance.runner }

  describe "#skip?" do
    context "when only_if returns false" do

      before do
        instance.only_if = false
      end

      it "returns true" do
        expect(runner.skip?).to eq(true)
      end

    end

    context "when only_if returns true" do

      before do
        instance.only_if = true
      end

      it "returns false" do
        expect(runner.skip?).to eq(false)
      end

    end
  end

  describe "#value_of" do

    context "when the key is a value" do
      it "returns the value" do
        expect(runner.value_of "value").to eq("value")
      end
    end

    context "when the key is a symbol" do
      context "when the key does not exist in context" do
        it "returns nil" do
          expect(runner.value_of :not_exist).to eq(nil)
        end
      end

      context "when the key exists in context" do
        before do
          runner.context.set :exists, "value"
        end

        it "returns the value" do
          expect(runner.value_of :exists).to eq("value")
        end
      end
    end

    context "when the key is a block" do
      let(:key) { lambda { "value" } }

      it "runs the block and returns the value" do
        expect(runner.value_of key).to eq("value")
      end
    end

  end

  describe "#yield_to" do

    context "when the key is a value" do
      it "raises an error" do
        expect {
          runner.yield_to "a value", "value"
        }.to raise_error(ArgumentError)
      end
    end

    context "when the key is a symbol" do
      it "sets the value in the context" do
        runner.yield_to :new_key, "value"
        expect(runner.context.get :new_key).to eq("value")
      end
    end

    context "when the key is a block" do
      it "passes the value to the block" do
        block = lambda { |x| set :from_block, x }
        runner.yield_to block, "value"
        expect(runner.context.get :from_block).to eq("value")
      end
    end

  end

  describe "#pretty" do

    context "when the value is runnable" do
      it "returns <code>" do
        block = lambda { some_code }
        expect(runner.pretty block).to eq("<code>")
      end
    end

    context "when the value is scalar" do
      it "returns the result of #inspect" do
        expect(runner.pretty "a string").to eq('"a string"')
      end
    end

    context "when the value is complex" do
      it "returns the result of #inspect" do
        expect(runner.pretty one: "two", three: 4).to eq('{:one=>"two", :three=>4}')
      end
    end

  end

end

