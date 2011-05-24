module Rack
  class Bug
    module FilteredBacktrace

      def backtrace
        @backtrace
      end

      def has_backtrace?
        filtered_backtrace_data.any?
      end

      def filtered_backtrace_data
        @filtered_backtrace ||= @backtrace.map{|l| l.to_s.strip }.map do |line|
          [line, filtered_backtrace_line?(line)]
        end
      end

      def filtered_backtrace_line?(line)
        app_path_pattern or
          return false

        line !~ app_path_pattern || line =~ app_vendor_path_pattern
      end

      def app_path_pattern
        @app_path_pattern ||= /\A#{Regexp.escape(root_for_backtrace_filtering)}/
      end

      def app_vendor_path_pattern
        @app_vendor_path_pattern ||= /\A#{Regexp.escape(root_for_backtrace_filtering('vendor'))}/
      end

      def root_for_backtrace_filtering(sub_path = nil)
        if defined?(Rails) && Rails.respond_to?(:root)
          (sub_path ? Rails.root.join(sub_path) : Rails.root).to_s
        else
          root = if defined?(RAILS_ROOT)
            RAILS_ROOT
          elsif defined?(ROOT)
            ROOT
          elsif defined?(Sinatra::Application)
            Sinatra::Application.root
          else
            nil
          end
          sub_path ? ::File.join(root, sub_path) : root
        end
      end
    end
  end
end
