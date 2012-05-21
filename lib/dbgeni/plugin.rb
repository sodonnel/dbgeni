module DBGeni
  class Plugin
    class << self
      attr_reader :hooks

      def install_plugin(hook, klass)
        unless @hooks.has_key? hook
          raise DBGeni::InvalidHook
        end
        @hooks[hook].push klass
      end

      def reset
        @hooks.keys.each do |k|
          @hooks[k] = Array.new
        end
      end

    end

    @hooks = {
      :before_migration_up   => [],
      :after_migration_up    => [],
      :before_migration_down => [],
      :after_migration_down  => [],
      :before_code_apply     => [],
      :after_code_apply      => [],
      :before_code_remove    => [],
      :after_code_remove     => [],
      :start_run             => [],
      :end_run               => []
    }


    def initialize
    end

    def load_plugins(path)
      begin
        files = Dir.entries(path).grep(/\.rb$/).sort
      rescue Exception => e
        raise e
      end
      files.each do |f|
        load_plugin File.join(path, f)
      end
    end

    def load_plugin(filename)
    end

    def run_plugins(hook, attrs)
      hooks = self.class.hooks[hook]
      unless hooks.is_a? Array
        raise DBGeni::InvalidHook, hook
      end

      hooks.each do |h|
        run_plugin h, attrs
      end
    end

    def run_plugin(klass, attrs)
      instance = klass.new
      unless instance.respond_to? :run
        raise DBGeni::PluginDoesNotRespondToRun
      end
      instance.run(attrs)
    end

  end
end

class Class
  DBGeni::Plugin.hooks.keys.each do |k|
    self.class_eval <<-end_eval
      def #{k.to_s}
        DBGeni::Plugin.install_plugin(:#{k.to_s}, self)
      end
    end_eval
  end
end

