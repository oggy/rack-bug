module Insight

  class CachePanel < Panel
    autoload :PanelApp, "insight/panels/cache_panel/panel_app"
    autoload :Stats,    "insight/panels/cache_panel/stats"

    def initialize(app)
      super

      probe(self) do
        instrument("Memcached") do
          instance_probe :decrement, :get, :increment, :set, :add,
            :replace, :delete, :prepend, :append
        end

        instrument("MemCache") do
          instance_probe :decr, :get, :get_multi, :incr, :set, :add, :delete
        end

        instrument("Dalli::Client") do
          instance_probe :perform
        end
      end

      table_setup("cache")
    end

    def request_start(env, start)
      @stats = Stats.new
    end

    def request_finish(env, st, hd, bd, timing)
      Rails.logger.debug "Stats: #@stats"
      store(env, @stats)
    end

    def after_detect(method_call, timing, args, result)
      method, key = method_call.method, args.first
      if defined? Dalli && Dalli::Client === method_call.object
        method, key = args[0], args[1]
      end
      @stats.record_call(method, timing.duration, !result.nil?, key)
    end

    def panel_app
      PanelApp.new
    end

    def name
      "cache"
    end

    def heading_for_request(number)
      stats = retreive(number).first
      "Cache: %.2fms (#{stats.queries.size} calls)" % stats.time
    end

    def content_for_request(number)
      stats = retreive(number).first
      render_template "panels/cache", :stats => stats
    end

  end

end
