require_relative './entity'
require_relative './task'
require_relative './eachtask'

module Pudl

  # A pipeline of tasks
  #
  class Pipeline < Entity

    attr_accessor :tasks, :on_error

    def initialize name
      super
      @tasks = {}
    end

    class Dsl < Entity::Dsl

      property_single :on_error do |v|
        if v.respond_to? :call
          entity.on_error = Task.parse :on_error, &v
        elsif v.is_a? Symbol
          entity.on_error = v
        else
          raise ArgumentError, "on_error must be a symbol or task block"
        end
      end

      def task name, &block
        task = Task.parse name, &block
        __add_task task
      end

      def eachtask name, &block
        task = EachTask.parse name, &block
        __add_task task
      end

      private

      def __add_task task
        if entity.tasks[task.name]
          raise ArgumentError, "Task #{task.name} already defined"
        end

        entity.tasks[task.name] = task
      end
    end

    class Runner < Entity::Runner

      def run *args
        if skip?
          logger.info "#{entity.name}: Skipping pipeline because only_if #{pretty entity.only_if} is false"
          return
        end

        logger.debug "#{entity.name}: Running #{entity.tasks.count} tasks"

          __run_tasks do |runner|
            runner.run
          end
      end

      def dry_run *args
        logger.debug "#{entity.name}: Not running #{entity.tasks.count} tasks"
        __run_tasks do |runner|
          runner.dry_run
        end
      end

      private

      def __run_tasks
        tasks = entity.tasks.values
        started = []
        done = []

        mutex = Mutex.new
        queue = Queue.new

        begin

          # Closure to handle tasks
          handle_task = lambda do |task|
            # Yield the runner rather than the task so we
            # only pass context in one place
            generated_tasks = yield task.runner(context)

            # This bit is a critical section
            mutex.synchronize do

              # This task is done, not started
              started -= [task.name]
              done    += [task.name]

              if context.abort?
                # If an abort request has been received then
                # do not add further tasks and set all unstarted
                # tasks to already done
                done += tasks.map(&:name).select { |t|
                  !started.include?(t) && !done.include?(t)
                }
              else
                # If any extra tasks were generated, add them
                # to the total list of tasks
                tasks = tasks.concat generated_tasks if generated_tasks.is_a? Array

                # Get the next batch of tasks with all dependencies met
                # (this will probably include all the newly added tasks
                # but not necessarily)
                ready_tasks = __next_tasks tasks, started, done
                started += ready_tasks.map &:name
                ready_tasks.each { |t| queue << t }
              end

              # We're finished if there's nothing running and
              # nothing left to do
              # Note that this will just signal each thread to
              # exit the next time it attempts to wait on the queue
              if started.empty? && queue.empty?
                (1..4).each { queue << nil }
              end
            end
          end

          Thread.abort_on_exception = true
          threads = (1..4).map do |threadnum|
            Thread.new do
              while task = queue.pop
                logger.debug "Thread #{threadnum} running #{pretty task.name}"
                handle_task[task]
              end
            end
          end

          # Add the initial batch of tasks with no dependencies
          ready_tasks = __next_tasks tasks, started, done
          started += ready_tasks.map &:name
          ready_tasks.each { |t| queue << t }

          # Wait for all the threads to complete
          threads.each(&:join)

          # If there are any tasks left over raise an error
          remainder = tasks.map(&:name) - done
          unless remainder.empty?
            raise RuntimeError, "Some tasks unreachable: #{remainder.map(&:inspect).join ", "}"
          end

        rescue => e

          # Try to run an error handler if anything went wrong
          on_error = __get_error_handler
          if on_error && !done.include?(on_error.name)
            on_error.runner(context).run
          end
          raise
        end
      end

      def __next_tasks tasks, started, done
        tasks.select { |task|
          !done.include? task.name
        }.select { |task|
          !started.include? task.name
        }.select { |task|
          task.after.all? { |dep| done.include? dep }
        }
      end

      def __get_error_handler
        if entity.on_error.is_a? BaseTask
          entity.on_error
        elsif entity.on_error.is_a? Symbol
          entity.tasks[entity.on_error]
        end
      end

    end

    dsl_class Dsl
    runner_class Runner

  end

end
