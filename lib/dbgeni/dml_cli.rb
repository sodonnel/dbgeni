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
  end

end
