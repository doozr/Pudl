require_relative '../lib/pudl'
require_relative './entity_behaviour'
require_relative './task_behaviour'

describe Pudl::Task do
  let(:name) { :test_task }
  subject { Pudl::Task }
  let(:instance) { subject.new name }

  it_behaves_like Pudl::Entity
  it_behaves_like Pudl::BaseTask

  describe "::add_actions" do
    let(:dsl) { Pudl::Task::Dsl.new instance }

    context "when an action is added" do
      after do
        Pudl.clear_actions
      end

      it "becomes available" do
        Pudl.add_actions({
          new_action: Pudl::BaseAction
        })
        expect(dsl).to respond_to(:new_action)
      end
    end

    context "when an action is removed" do
      before do
        Pudl.add_actions({
          new_action: Pudl::BaseAction
        })
      end

      it "is no longer available" do
        Pudl.clear_actions
        expect(dsl).not_to respond_to(:new_action)
      end
    end

    context "when an action doesn't exist" do
      it "raises a method missing error" do
        expect {
          dsl.not_exist "name" do
          end
        }.to raise_error(NoMethodError)
      end
    end

    context "when an action exists" do
      before do
        Pudl.add_actions({
          exist: Pudl::BaseAction
        })
      end

      after do
        Pudl.clear_actions
      end

      it "creates the action" do
        dsl.exist "test action name" do
        end
        expect(instance.actions[0].name).to eq("test action name")
      end
    end
  end

  describe "#parse" do
    it_behaves_like Pudl::Entity::Dsl
    it_behaves_like Pudl::BaseTask::Dsl

    before do
      Pudl.add_actions({
        dothing: Pudl::BaseAction
      })
    end

    after do
      Pudl.clear_actions
    end

    context "when actions are added" do
      let(:instance) {
        subject.parse name do
          dothing "an action" do
          end

          dothing "another action" do
          end

          dothing "a third action" do
          end
        end
      }

      it "adds actions in order" do
        expect(instance.actions.length).to eq(3)
        expect(instance.actions[0].name).to eq("an action")
        expect(instance.actions[1].name).to eq("another action")
        expect(instance.actions[2].name).to eq("a third action")
      end
    end

    context "when an action with the same name exists" do
      let(:instance) {
        subject.parse name do
          dothing "an action" do
          end

          dothing "an action" do
          end
        end
      }

      it "add the action" do
        expect(instance.actions[0].name).to eq("an action")
        expect(instance.actions[1].name).to eq("an action")
      end
    end

    context "when no action name is supplied" do
      let(:instance) {
        subject.parse name do
          dothing do
          end
        end
      }

      it "creates a name from the task name and action type" do
        expect(instance.actions[0].name).to eq("#{name}:dothing")
      end
    end
  end

  describe "#runner" do
    it_behaves_like Pudl::Entity::Runner

    let(:runner) { instance.runner }

    def stub_action_runner action
      r = action.runner
      allow(action).to receive(:runner).and_return(r)
      r
    end

    before do
      Pudl.add_actions({
        dothing: Pudl::BaseAction,
        ruby:    Pudl::Actions::RubyAction
      })
    end

    after do
      Pudl.clear_actions
    end

    context "when no error occurs" do
      let(:instance) {
        subject.parse name do
          dothing "first action" do
          end

          dothing "second action" do
          end

          dothing "third action" do
          end
        end
      }

      it "runs all actions in order" do
        expect(stub_action_runner instance.actions[0]).to receive(:run) do
          expect(stub_action_runner instance.actions[1]).to receive(:run) do
            expect(stub_action_runner instance.actions[2]).to receive(:run)
          end
        end
        runner.run
      end
    end

    context "when the pipeline is aborted" do
      let(:instance) {
        subject.parse name do
          dothing "first thing" do
          end

          ruby do
            code do
              abort 123
            end
          end

          dothing "second thing" do
          end
        end
      }

      it "runs all actions up until the one that aborts" do
        expect(stub_action_runner instance.actions[0]).to receive(:run) do
          expect(stub_action_runner instance.actions[1]).to receive(:run)
        end
        runner.run
      end

      it "does not run subsequent actions" do
        expect(stub_action_runner instance.actions[2]).not_to receive(:run)
        runner.run
      end

      it "does not raise an error" do
        expect {
          runner.run
        }.not_to raise_error
      end
    end

    context "when an error occurs" do
      context "and there is an error handler" do
        let(:instance) {
          subject.parse name do
            dothing "first action" do
            end

            dothing "second action" do
            end

            dothing "third action" do
            end

            on_error do |e|
              raise(RuntimeError, "Error handler has been run: " + e.message)
            end
          end
        }

        let(:error) {
          RuntimeError.new "An error happened"
        }

        before do
          allow(stub_action_runner instance.actions[1]).to receive(:run) { raise  error }
        end

        it "calls the error handler with the exception" do
          expect {
            runner.run
          }.to raise_error(RuntimeError, "Error handler has been run: An error happened")
        end

        it "does not execute subsequent tasks" do
          expect(stub_action_runner instance.actions[0]).to receive(:run)
          expect(stub_action_runner instance.actions[1]).to receive(:run)
          expect(stub_action_runner instance.actions[2]).not_to receive(:run)
          begin
            runner.run
          rescue
          end
        end
      end

      context "and there is no error handler" do
        let(:instance) {
          subject.parse name do
            dothing "first action" do
            end

            dothing "second action" do
            end

            dothing "third action" do
            end
          end
        }

        before do
          allow(stub_action_runner instance.actions[1]).to receive(:run) { raise RuntimeError, "An error happened" }
        end

        it "raises an error" do
          expect { runner.run }.to raise_error(RuntimeError, "An error happened")
        end

        it "does not execute subsequent tasks" do
          expect(stub_action_runner instance.actions[0]).to receive(:run)
          expect(stub_action_runner instance.actions[1]).to receive(:run)
          expect(stub_action_runner instance.actions[2]).not_to receive(:run)
          begin
            runner.run
          rescue
          end
        end
      end
    end

  end
end
