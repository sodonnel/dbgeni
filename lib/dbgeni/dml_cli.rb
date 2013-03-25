module DBGeni

  class DmlCLI < MigrationCLI

    BEFORE_UP_RUN_PLUGIN   = :before_dml_up
    AFTER_UP_RUN_PLUGIN    = :after_dml_up
    BEFORE_DOWN_RUN_PLUGIN = :before_dml_down
    AFTER_DOWN_RUN_PLUGIN  = :after_dml_down
    BEFORE_RUNNING_PLUGIN  = :before_running_dml
    AFTER_RUNNING_PLUGIN   = :after_running_dml

    def migrations
      @migration_list ||= DBGeni::MigrationList.new_dml_migrations(@config.dml_directory) unless @migration_list
      @migration_list.migrations
    end

    private

    def find_migration(migration_name)
      m = Migration.initialize_from_internal_name(@config.dml_directory, migration_name)
    end

    def set_plugin_hooks
      @before_up_run_plugin   = :before_dml_up
      @after_up_run_plugin    = :after_dml_up
      @before_down_run_plugin = :before_dml_down
      @after_down_run_plugin  = :after_dml_down
      @before_running_plugin  = :before_running_dmls
      @after_running_plugin   = :after_running_dmls
    end


  end

end
