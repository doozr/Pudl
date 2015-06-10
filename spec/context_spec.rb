require_relative '../lib/pudl/context'

describe Pudl::Context do

  subject { Pudl::Context.new }

  it "raises an error if key is not a symbol" do
    expect {
      subject.set "not a symbol", "value"
    }.to raise_error(ArgumentError)
  end

  it "has no values" do
    expect(subject.values).to eq({})
  end

  describe "#get and #set" do

    it "returns nil for a missing value" do
      expect(subject.get :notthere).to eq(nil)
    end

    it "returns a set value" do
      subject.set :testkey, "here it is"
      expect(subject.get :testkey).to eq("here it is")
      expect(subject.values).to eq({
        testkey: "here it is"
      })
    end

    it "overwrites an existing value" do
      subject.set :testkey, "here it is"
      subject.set :testkey, "overridden"
      expect(subject.get :testkey).to eq("overridden")
      expect(subject.values).to eq({
        testkey: "overridden"
      })
    end

    it "passes nil to a block if value does not exist" do
      subject.set :testkey do |x|
        x.class.name
      end
      expect(subject.get :testkey).to eq("NilClass")
    end

    it "passed current value to a block if value does exist" do
      subject.set :testkey, "here it is"
      subject.set :testkey do |x|
        x + " - yes"
      end
      expect(subject.get :testkey).to eq("here it is - yes")
    end

    it "sets the result to the value of a block" do
      subject.set :testkey do
        "something"
      end
      expect(subject.get :testkey).to eq("something")
    end

    it "closes over local variables" do
      x = "result"
      subject.set :testkey do
        x
      end
      expect(subject.get :testkey).to eq("result")
    end

    it "raises an error if a value and a block is provided" do
      expect {
        subject.set :testkey, :wrong do
        end
      }
    end

    it "does not raise an error if another context method is called in the block" do
      subject.set :value, "one"
      subject.set :final do
        get :value
      end
    end

    it "allows calls to get inside set blocks" do
      expect {
        subject.set :thing do
          get :thing
        end
      }.not_to raise_error
    end

    it "allows calls to set inside set blocks" do
      expect {
        subject.set :thing do
          set :thing, "value"
        end
      }.not_to raise_error
    end

    it "allows nested set blocks" do
      expect {
        subject.set :thing do
          set :another do
            get :thing
          end
        end
      }.not_to raise_error
    end

    it "allows calls to #abort inside set blocks" do
      expect {
        subject.set :thing do
          abort
        end
      }.not_to raise_error
    end

    it "allows calls to #abort? inside set blocks" do
      expect {
        subject.set :thing do
          abort?
        end
      }.not_to raise_error
    end

    it "allows called to #exit_code inside set blocks" do
      expect {
        subject.set :thing do
          exit_code
        end
      }.not_to raise_error
    end

  end

  describe "#abort, #abort? and #exit_code" do

    context "not aborted" do
      it "#abort? returns false" do
        expect(subject.abort?).to eq(false)
      end

      it "sets exit_code to 0" do
        expect(subject.exit_code).to eq(0)
      end
    end

    context "aborted with no exit code" do
      before do
        subject.abort
      end

      it "#abort? returns true" do
        expect(subject.abort?).to eq(true)
      end

      it "sets exit code to 1" do
        expect(subject.exit_code).to eq(1)
      end
    end

    context "aborted with exit code" do
      before do
        subject.abort 123
      end

      it "#abort? returns true" do
        expect(subject.abort?).to eq(true)
      end

      it "sets exit code to provided value" do
        expect(subject.exit_code).to eq(123)
      end
    end

  end

end
