require_relative '../lib/pudl'
require_relative './entity_behaviour'

describe Pudl::Pipeline do

  let(:name) { "test.pipeline" }
  subject { Pudl::Pipeline }
  let(:instance) { subject.new name }

  it_behaves_like Pudl::Entity

  describe "#tasks" do
    it_behaves_like :attr_accessor, :tasks
  end

  describe "on_error" do
    it_behaves_like :attr_accessor, :on_error
  end

  describe "#parse" do
    it_behaves_like Pudl::Entity::Dsl

    shared_examples_for "tasks" do |method|
      context "when task already exists" do
        let(:instance) {
          subject.parse do
            task :already_exists do
            end

            task :already_exists do
            end
          end
        }

        it "raises an error" do
          expect {
            instance
          }.to raise_error(ArgumentError)
        end
      end

      context "when name is not a symbol" do
        let(:instance) {
          subject.parse do
            send method, "not a symbol" do
            end
          end
        }

        it "raises an error" do
          expect {
            instance
          }.to raise_error(ArgumentError)
        end
      end
    end

    describe "#task" do
      include_examples "tasks", :task

      context "when task does not already exist" do
        let(:instance) {
          subject.parse name do
            task :a_task do
            end

            task :does_not_exist do
            end
          end
        }

        it "creates a Pudl::Task}" do
          expect(instance.tasks[:a_task]).to be_a(Pudl::Task)
          expect(instance.tasks[:does_not_exist]).to be_a(Pudl::Task)
        end
      end
    end

    describe "#eachtask" do
      include_examples "tasks", :eachtask

      context "when task does not already exist" do
        let(:instance) {
          subject.parse name do
            eachtask :a_task do
            end

            eachtask :does_not_exist do
            end
          end
        }

        it "creates a Pudl::EachTask" do
          expect(instance.tasks[:a_task_generator]).to be_a(Pudl::EachTask)
          expect(instance.tasks[:does_not_exist_generator]).to be_a(Pudl::EachTask)
        end
      end
    end

    describe "#on_error" do
      context "no block is included" do
        it "does not accept a non-symbol name" do
          expect {
            subject.parse name do
              on_error "a task"
            end
          }.to raise_error(ArgumentError)
        end

        it "sets the value" do
          pipeline = subject.parse name do
            on_error :a_task
          end
          expect(pipeline.on_error).to eq(:a_task);
        end
      end

      context "when a block is included" do
        it "does not accept a name and a block" do
          expect {
            subject.parse name do
              on_error :on_error_task do
              end
            end
          }.to raise_error(ArgumentError)
        end

        context "creates a task from the block" do
          it "creates a task with the specified name from the block" do
            pipeline = subject.parse name do
              on_error do
              end
            end
            expect(pipeline.on_error).to be_a(Pudl::Task)
            expect(pipeline.on_error.name).to be(:on_error)
          end
        end
      end
    end

  end

  describe "#runner" do
    it_behaves_like Pudl::Entity::Runner

    let(:runner) { instance.runner }

    def stub_task_runner task
      task = instance.tasks[task] if task.is_a? Symbol
      r = task.runner
      allow(task).to receive(:runner).and_return(r)
      r
    end

    context "if #skip? returns true" do
      let(:instance) {
        subject.parse name do
          only_if false
          task :only_task do
          end
        end
      }

      it "does not run any tasks" do
        expect(instance.tasks[:only_task]).not_to receive(:runner)
        runner.run
      end
    end

    context "when there is one task" do
      let(:instance) {
        subject.parse name do
          task :only_task do
          end
        end
      }

      it "runs the task" do
        expect(stub_task_runner :only_task).to receive(:run)
        runner.run
      end
    end

    context "when there are two tasks" do
      let(:instance) {
        subject.parse name do
          task :first_task do
          end
          task :second_task do
          end
        end
      }

      it "runs the task" do
        expect(stub_task_runner :first_task).to receive(:run)
        expect(stub_task_runner :second_task).to receive(:run)
        runner.run
      end
    end

    context "when a task is unreachable" do
      let(:instance) {
        subject.parse name do
          task :first_task do
          end
          task :second_task do
            after :third_task
          end
        end
      }

      it "raises an error" do
        expect(stub_task_runner :second_task).not_to receive(:run)
        expect {
          runner.run
        }.to raise_error(RuntimeError, "Some tasks unreachable: :second_task")
      end
    end

    context "when tasks have dependencies" do
      context "and a task is dependent on another" do
        let(:instance) {
          subject.parse name do
            task :first_task do
              after :second_task
            end
            task :second_task do
            end
          end
        }

        it "runs dependent after the dependency" do
          expect(stub_task_runner :second_task).to receive(:run) do
            expect(stub_task_runner :first_task).to receive(:run)
          end
          runner.run
        end
      end

      context "and two tasks are dependent on one other" do
        let(:instance) {
          subject.parse name do
            task :first_task do
              after :third_task
            end
            task :second_task do
              after :third_task
            end
            task :third_task do
            end
          end
        }

        it "runs both dependents after the dependency" do
          expect(stub_task_runner :third_task).to receive(:run) do
            expect(stub_task_runner :first_task).to receive(:run)
            expect(stub_task_runner :second_task).to receive(:run)
          end
          runner.run
        end
      end

      context "and one task is dependent on two others" do
        let(:instance) {
          subject.parse name do
            task :first_task do
              after :second_task, :fourth_task
            end
            task :second_task do
              after :third_task
            end
            task :third_task do
            end
            task :fourth_task do
            end
          end
        }

        it "runs the dependencies" do
          expect(stub_task_runner :second_task).to receive(:run)
          expect(stub_task_runner :fourth_task).to receive(:run)
          runner.run
        end

        it "does not run the dependencies after the dependent" do
          expect(stub_task_runner :first_task).to receive(:run) do
            expect(stub_task_runner :second_task).not_to receive(:run)
            expect(stub_task_runner :fourth_task).not_to receive(:run)
          end
          runner.run
        end
      end

      context "and there are dynamically generated tasks" do
        let(:instance) {
          subject.parse name do
            task :first_task do
            end

            eachtask :second_task do
              after :first_task
              source (1..3)
              task do |n|
              end
            end

            task :third_task do
              after :second_task
            end
          end
        }

        let(:generated_tasks) {
          instance.tasks[:second_task_generator].runner.run
        }

        let(:dynamic_task_0) { generated_tasks[0] }
        let(:dynamic_task_1) { generated_tasks[1] }
        let(:dynamic_task_2) { generated_tasks[2] }
        let(:second_task) { generated_tasks[3] }

        before do
          allow(stub_task_runner :second_task_generator).to receive(:run).and_return(generated_tasks)
        end

        it "runs dynamic tasks after the generator's dependencies" do
          expect(stub_task_runner :first_task).to receive(:run) do
            expect(stub_task_runner dynamic_task_0).to receive(:run)
            expect(stub_task_runner dynamic_task_1).to receive(:run)
            expect(stub_task_runner dynamic_task_2).to receive(:run)
          end
          runner.run
        end

        it "does not run the dynamic tasks after the end task" do
          expect(stub_task_runner second_task).to receive(:run) do
            expect(stub_task_runner dynamic_task_0).not_to receive(:run)
            expect(stub_task_runner dynamic_task_1).not_to receive(:run)
            expect(stub_task_runner dynamic_task_2).not_to receive(:run)
          end
          runner.run
        end

        it "runs tasks dependent on the generator after the end task" do
          expect(stub_task_runner second_task).to receive(:run) do
            expect(stub_task_runner :third_task).to receive(:run)
          end
          runner.run
        end

      end

    end

    context "when the pipeline is aborted" do
      let(:instance) {
        subject.parse name do
          task :first_task do
          end

          task :second_task do
            after :first_task
          end

          task :third_task do
            after :second_task
          end
        end
      }

      before do
        allow(stub_task_runner :second_task).to receive(:run) do
          runner.context.abort 101
        end
      end

      it "runs all tasks up to the one that aborts" do
        expect(stub_task_runner :first_task).to receive(:run) do
          expect(stub_task_runner :second_task).to receive(:run)
        end
        runner.run
      end

      it "does not run subsequent tasks" do
        expect(stub_task_runner :third_task).not_to receive(:run)
        runner.run
      end

      it "does not raise an error" do
        expect { runner.run }.not_to raise_error
      end
    end

    context "when an error handler is supplied" do
      context "and no error occurs" do
        let(:instance) {
          subject.parse name do
            task :first_task do
              after :second_task
            end
            task :second_task do
            end
            on_error do
            end
          end
        }

        it "runs all tasks" do
          expect(stub_task_runner :first_task).to receive(:run)
          expect(stub_task_runner :second_task).to receive(:run)
          runner.run
        end
      end

      context "and an error occurs" do

        context "and on_error is a symbol" do
          context "and tasks are in progress" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                end
                task :second_task do
                end
                task :clean_up do
                  after :second_task
                end
                on_error :clean_up
              end
            }

            it "completes the in-progress task" do
              expect(stub_task_runner :first_task).to receive(:run)
              expect(stub_task_runner :second_task).to receive(:run).and_raise(RuntimeError)
              expect(stub_task_runner :clean_up).to receive(:run)
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end 
          end

          context "and there are unstarted tasks" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                  after :second_task
                end
                task :second_task do
                end
                task :clean_up do
                  after :first_task
                end
                on_error :clean_up
              end
            }

            it "does not run unstarted tasks" do
              expect(stub_task_runner :second_task).to receive(:run).and_raise(RuntimeError) do
                expect(stub_task_runner :first_task).to receive(:run)
              end
              expect(stub_task_runner :clean_up).to receive(:run)
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end
          end
          context "and the named task does not exist" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                  after :second_task
                end
                task :second_task do
                end
                on_error :clean_up
              end
            }

            it "raises the original error" do
              expect(stub_task_runner :second_task).to receive(:run).and_raise(RuntimeError)
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end
          end

          context "and the named task has already run" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                  after :second_task
                end
                task :second_task do
                end
                task :clean_up do
                end
                on_error :clean_up
              end
            }

            it "does not call the task" do
              expect(stub_task_runner :first_task).to receive(:run).and_raise(RuntimeError)
              expect(stub_task_runner :clean_up).to receive(:run).once
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end
          end

          context "and a task is unreachable" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                  after :third_task
                end
                task :second_task do
                end
                task :clean_up do
                  after :second_task
                end
                on_error :clean_up
              end
            }

            it "calls the error handler" do
              expect(stub_task_runner instance.on_error).to receive(:run)
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end
          end
        end

        context "and on_error is a task" do
          context "and tasks are in progress" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                end
                task :second_task do
                end
                on_error do
                end
              end
            }

            it "completes the in-progress task" do
              expect(stub_task_runner :first_task).to receive(:run)
              expect(stub_task_runner :second_task).to receive(:run).and_raise(RuntimeError)
              expect(stub_task_runner instance.on_error).to receive(:run)
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end 
          end

          context "and there are unstarted tasks" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                  after :second_task
                end
                task :second_task do
                end
                on_error do
                end
              end
            }

            it "does not run unstarted tasks" do
              expect(stub_task_runner :second_task).to receive(:run).and_raise(RuntimeError) do
                expect(stub_task_runner :first_task).to receive(:run)
              end
              expect(stub_task_runner instance.on_error).to receive(:run)
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end
          end

          context "and a task is unreachable" do
            let(:instance) {
              subject.parse name do
                task :first_task do
                  after :third_task
                end
                task :second_task do
                end
                on_error do
                end
              end
            }

            it "calls the error handler" do
              expect(stub_task_runner instance.on_error).to receive(:run)
              expect {
                runner.run
              }.to raise_error(RuntimeError)
            end
          end
        end
      end
    end
  end

end
