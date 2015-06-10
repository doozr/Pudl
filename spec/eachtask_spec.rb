require_relative '../lib/pudl'
require_relative './entity_behaviour'
require_relative './task_behaviour'

describe Pudl::EachTask do
  let(:name) { :test_task_generator }
  let(:basename) { :test_task }
  subject { Pudl::EachTask }
  let(:instance) { subject.new basename }

  it_behaves_like Pudl::Entity
  it_behaves_like Pudl::BaseTask

  describe "#name" do
    it "appends _generator to provided name" do
      task = subject.new basename
      expect(task.name).to eq(name)
      expect(task.basename).to eq(basename)
    end
  end

  describe "#source" do
    it_behaves_like :attr_accessor, :source
  end

  describe "#parse" do
    it_behaves_like Pudl::Entity::Dsl
    it_behaves_like Pudl::BaseTask::Dsl

    describe "#source" do
      it_behaves_like :property_single, :source
    end

    describe "#task" do
      it "accepts a block" do
        entity = subject.parse basename do
          task do
            "a block"
          end
        end
        expect(entity.task.call).to eq("a block")
      end

      it "raises an error if there is no block" do
        expect {
          subject.parse basename do
            task
          end
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#runner" do
    it_behaves_like Pudl::Entity::Runner

    let(:runner) { instance.runner }

    context "when skip? returns true" do
      let(:instance) {
        subject.parse basename do
          source [1,2,3]
          task do
          end
          only_if false
        end
      }

      it "returns a single task with the base name and no actions" do
        tasks = runner.run
        expect(tasks.length).to eq(1)
        expect(tasks.first.name).to eq(basename)
        expect(tasks.first.actions).to eq([])
      end
    end

    context "when skip? returns false" do

      context "and the source is an array" do
        context "and the array is empty" do
          let(:source_array) {
            []
          }

          context "and the source is an array" do
            let(:instance) {
              a = source_array
              subject.parse basename do
                source a
                task do
                end
              end
            }

            it "returns a single task with the base name and no actions" do
              tasks = runner.run
              expect(tasks.length).to eq(1)
              expect(tasks.first.name).to eq(basename)
              expect(tasks.first.actions).to eq([])
            end
          end

          context "and the source is a context variable" do
            let(:instance) {
              subject.parse basename do
                source :my_var
                task do
                end
              end
            }

            before do
              runner.context.set :my_var, source_array
            end

            it "returns a single task with the base name and no actions" do
              tasks = runner.run
              expect(tasks.length).to eq(1)
              expect(tasks.first.name).to eq(basename)
              expect(tasks.first.actions).to eq([])
            end
          end

          context "and the source is a block" do
            let(:instance) {
              a = source_array
              subject.parse basename do
                source do
                  a
                end
                task do
                end
              end
            }

            it "returns a single task with the base name and no actions" do
              tasks = runner.run
              expect(tasks.length).to eq(1)
              expect(tasks.first.name).to eq(basename)
              expect(tasks.first.actions).to eq([])
            end
          end
        end

        context "and the array is not empty" do
        end
      end

      context "and the source is a hash" do
        context "and the hash is empty" do
        end

        context "and the hash is not empty" do
        end
      end

      context "and the source is neither a hash or an array" do
      end

    end
  end
end

