# Creates a overall framework to define a reusable job.
#
# A custom job module can extend `RunnableJob` and overrides `metrics` and `validate_state`
#
module DashingContrib
  module RunnableJob
    extend self
    WARNING  = 'warning'.freeze
    CRITICAL = 'critical'.freeze
    OK       = 'ok'.freeze

    def run(options = {}, &block)
      user_options = _merge_options(options)
      event_name   = user_options.delete(:event)
      interval     = user_options.delete(:every)
      block.call if block_given?
      _scheduler.every interval, user_options do
        current_metrics = metrics(options)
        current_state   = validate_state(current_metrics, user_options)
        send_event(event_name, current_metrics.merge({ state: current_state }))
      end
    end

    # Overrides this method to fetch and generate metrics
    # Return value should be the final metrics to be used in the user interface
    # Arguments:
    #   options :: options provided by caller in `run` method
    def metrics(options)
      {}
    end

    # Always return a common state, override this with your custom logic
    # Common states are WARNING, CRITICAL, OK
    # Arguments:
    #   metrics :: calculated metrics provided `metrics` method
    #   user_options :: hash provided by user options
    def validate_state(metrics, user_options)
      OK
    end

    private
    def _scheduler
      SCHEDULER
    end

    def _merge_options(options)
      raise ':event String is required to identify a job name' if options[:event].nil?
      _default_scheduler_options.merge(options)
    end

    def _default_scheduler_options
      {
        every: '30s',
        first_in: 0
      }
    end
  end
end