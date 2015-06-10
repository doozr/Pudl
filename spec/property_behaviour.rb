shared_examples_for :property_single do |method|
  it "accepts a single value" do
    expect {
      subject.parse name do
        send method, "value"
      end
    }.not_to raise_error
  end

  it "does not accept multiple values" do
    expect {
      subject.parse name do
        send method, "value", "another value", "a third value"
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts a block" do
    expect {
      subject.parse name do
        send method do
          "value"
        end
      end
    }.not_to raise_error
  end

  it "does not accept a block and a value" do
    expect {
      subject.parse name do
        send method, "value" do
          "another value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts no values" do
    expect {
      subject.parse name do
        send method
      end
    }.not_to raise_error
  end
end

shared_examples_for :property_single_static do |method|
  it "accepts a single value" do
    expect {
      subject.parse name do
        send method, "value"
      end
    }.not_to raise_error
  end

  it "does not accept multiple values" do
    expect {
      subject.parse name do
        send method, "value", "another value", "a third value"
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a block" do
    expect {
      subject.parse name do
        send method do
          "value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a block and a value" do
    expect {
      subject.parse name do
        send method, "value" do
          "another value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts no values" do
    expect {
      subject.parse name do
        send method
      end
    }.not_to raise_error
  end
end

shared_examples_for :property_multi do |method|
  it "accepts a single value" do
    expect {
      subject.parse name do
        send method, "value"
      end
    }.not_to raise_error
  end

  it "accepts multiple values" do
    expect {
      subject.parse name do
        send method, "value", "another value", "a third value"
      end
    }.not_to raise_error
  end

  it "accepts a block" do
    expect {
      subject.parse name do
        send method do
          "value"
        end
      end
    }.not_to raise_error
  end

  it "does not accept a block and a value" do
    expect {
      subject.parse name do
        send method, "value" do
          "another value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts no values" do
    expect {
      subject.parse name do
        send method
      end
    }.not_to raise_error
  end
end

shared_examples_for :property_multi_static do |method|
  it "accepts a single value" do
    expect {
      subject.parse name do
        send method, "value"
      end
    }.not_to raise_error
  end

  it "accepts multiple values" do
    expect {
      subject.parse name do
        send method, "value", "another value", "a third value"
      end
    }.not_to raise_error
  end

  it "does not accept a block" do
    expect {
      subject.parse name do
        send method do
          "value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a block and a value" do
    expect {
      subject.parse name do
        send method, "value" do
          "another value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts no values" do
    expect {
      subject.parse name do
        send method
      end
    }.not_to raise_error
  end
end

shared_examples_for :property_keyval do |method|
  it "accepts a symbol and a value" do
    expect {
      subject.parse name do
        send method, :symbol, "value"
      end
    }.not_to raise_error
  end

  it "accepts a symbol and a block" do
    expect {
      subject.parse name do
        send method, :symbol do
          "value"
        end
      end
    }.not_to raise_error
  end

  it "does not accept a non-symbol and a value" do
    expect {
      subject.parse name do
        send method, "symbol", "value"
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a non-symbol and a block" do
    expect {
      subject.parse name do
        send method, "symbol" do
          "value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts a symbol" do
    expect {
      subject.parse name do
        send method, :symbol
      end
    }.not_to raise_error
  end
end

shared_examples_for :property_keyval_static do |method|
  it "accepts a symbol and a value" do
    expect {
      subject.parse name do
        send method, :symbol, "value"
      end
    }.not_to raise_error
  end

  it "does not accept a symbol and a block" do
    expect {
      subject.parse name do
        send method, :symbol do
          "value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a non-symbol and a value" do
    expect {
      subject.parse name do
        send method, "symbol", "value"
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a non-symbol and a block" do
    expect {
      subject.parse name do
        send method, "symbol" do
          "value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts a symbol" do
    expect {
      subject.parse name do
        send method, :symbol
      end
    }.not_to raise_error
  end
end

shared_examples_for :property_out do |method|
  it "accepts a single symbol" do
    expect {
      subject.parse name do
        send method, :symbol
      end
    }.not_to raise_error
  end

  it "does not accept multiple symbols" do
    expect {
      subject.parse name do
        send method, :symbol, :symbol_another
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a single value" do
    expect {
      subject.parse name do
        send method, "value"
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept multiple values" do
    expect {
      subject.parse name do
        send method, "value", "another value", "a third value"
      end
    }.to raise_error(ArgumentError)
  end

  it "accepts a block" do
    expect {
      subject.parse name do
        send method do
          "value"
        end
      end
    }.not_to raise_error
  end

  it "does not accept a block and a symbol" do
    expect {
      subject.parse name do
        send method, :symbol do
          "another value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept a block and a value" do
    expect {
      subject.parse name do
        send method, "value" do
          "another value"
        end
      end
    }.to raise_error(ArgumentError)
  end

  it "does not accept no value" do
    expect {
      subject.parse name do
        send method
      end
    }.to raise_error(ArgumentError)
  end
end
