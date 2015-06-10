require_relative '../lib/pudl'
require_relative './property_behaviour'

describe "Property types" do

  class Dummy < Pudl::Entity

    class Dsl < Pudl::Entity::Dsl

      property_single :single do |v|
      end

      property_single_static :single_static do |v|
      end

      property_multi :multi do |*args|
      end

      property_multi_static :multi_static do |*args|
      end

      property_keyval :keyval do |k, v|
      end

      property_keyval_static :keyval_static do |k, v|
      end

      property_out :out do |v|
      end

    end

    dsl_class Dsl

  end

  subject { Dummy }
  let(:name) { "property types test" }

  describe :property_single do
    include_examples :property_single, :single
  end

  describe :property_single_static do
    include_examples :property_single_static, :single_static
  end

  describe :property_multi do
    include_examples :property_multi, :multi
  end

  describe :property_multi_static do
    include_examples :property_multi_static, :multi_static
  end

  describe :property_keyval do
    include_examples :property_keyval, :keyval
  end

  describe :property_keyval_static do
    include_examples :property_keyval_static, :keyval_static
  end

  describe :property_out do
    include_examples :property_out, :out
  end

end
