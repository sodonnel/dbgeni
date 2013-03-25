module DBGeni
  class MigrationCLI
    
    def initialize(base_installer, config, logger)
      @base       = base_installer
      @config     = config
      @logger     = logger
      set_plugin_hooks
    end
    
    def migrations
      @migration_list ||= DBGeni::MigrationList.new(@config.migration_directory) unless @migration_list
      @migration_list.migrations
    end

    def outstanding_migrations
      ensure_initialized
      migrations
      @migration_list.outstanding(@config, connection)
    end

    def applied_migrations
      ensure_initialized
      migrations
      @migration_list.applied(@config, connection)
    end
    
    def applied_and_broken_migrations
      ensure_initialized
      migrations
      @migration_list.applied_and_broken(@config, connection)
    end

    def list_of_migrations(list)
      ensure_initialized
      migrations
      @migration_list.list(list, @config, connection)
    end
    
    # Applying
    
    def apply_all_migrations(force=nil)
      ensure_initialized
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      apply_migration_list(migrations, force)
    end
    
    def apply_next_migration(force=nil)
      ensure_initialized
      migrations = outstanding_migrations
      if migrations.length == 0
        raise DBGeni::NoOutstandingMigrations
      end
      apply_migration_list([migrations.first], force)
    end

    def apply_until_migration(migration_name, force=nil)
      ensure_initialized
      milestone = find_migration(migration_name)
      outstanding = outstanding_migrations
      index = outstanding.index milestone
      unless index
        # milestone migration doesn't exist or is already applied.
        raise MigrationNotOutstanding, milestone.to_s
      end
      apply_migration_list(outstanding[0..index], force)
    end
    
    def apply_list_of_migrations(migration_list, force=nil)
      ensure_initialized
      migration_files = list_of_migrations(migration_list)
      apply_migration_list(migration_files, force)
    end
    
    
    def apply_migration(migration, force=nil)
      ensure_initialized
      begin
        run_plugin(@before_up_run_plugin, migration)
        migration.apply!(@config, connection, force)
        @logger.info "Applied #{migration.to_s}"
        run_plugin(@after_up_run_plugin, migration)
      rescue DBGeni::MigrationApplyFailed
        @logger.error "Failed #{migration.to_s}. Errors in #{migration.logfile}\n\n#{migration.error_messages}\n\n"
        raise DBGeni::MigrationApplyFailed, migration.to_s
      end
    end
    
    # rolling back
    
    def rollback_all_migrations(force=nil)
      ensure_initialized
      migrations = applied_and_broken_migrations.reverse
      if migrations.length == 0
        raise DBGeni::NoAppliedMigrations
      end
      apply_migration_list(migrations, force, false)
    end
    
    def rollback_last_migration(force=nil)
      ensure_initialized
      migrations = applied_and_broken_migrations
      if migrations.length == 0
        raise DBGeni::NoAppliedMigrations
      end
      # the most recent one is at the end of the array!!
      apply_migration_list([migrations.last], force, false)
    end
    
    def rollback_until_migration(migration_name, force=nil)
      ensure_initialized
      milestone = find_migration(migration_name)
      applied = applied_and_broken_migrations.reverse
      index = applied.index milestone
      unless index
        # milestone migration doesn't exist or is already applied.
        raise DBGeni::MigrationNotApplied, milestone.to_s
      end
      # Note the triple ... in the range to exclude the end element
      # This is because we don't want to rollback the final migration as its upto but not including
      apply_migration_list(applied[0...index], force, false)
    end
    
    def rollback_list_of_migrations(migration_list, force=nil)
      ensure_initialized
      migration_files = list_of_migrations(migration_list).reverse
      apply_migration_list(migration_files, force, false)
    end
    
    def rollback_migration(migration, force=nil)
      ensure_initialized
      begin
        run_plugin(@before_down_run_plugin, migration)
        migration.rollback!(@config, connection, force)
        @logger.info  "Rolledback #{migration.to_s}"
        run_plugin(@after_down_run_plugin, migration)
      rescue DBGeni::MigrationApplyFailed
        @logger.error "Failed #{migration.to_s}. Errors in #{migration.logfile}\n\n#{migration.error_messages}\n\n"
        raise DBGeni::MigrationApplyFailed, migration.to_s
      end
    end
    
    private
    
    def apply_migration_list(migration_list, force, up=true)
      # TODO - conflicted about how to handle exceptions.
      # If before_running_migrations throws an exception no
      # migrations will be run.
      # If a migration throws an exception, then after_running_migrations
      # will not be run.
      params = {
        :operation => up == true ? 'apply' : 'remove'
      }
      run_plugin(@before_running_plugin, migration_list, params)
      migration_list.each do |m|
        if up
          apply_migration(m, force)
        else
          rollback_migration(m, force)
        end
      end
      run_plugin(@after_running_plugin, migration_list, params)
    end

    def run_plugin(hook, object, params={})
      @base.run_plugin(hook, object, params)
    end

    private

    def find_migration(migration_name)
      m = Migration.initialize_from_internal_name(@config.migration_directory, migration_name)
    end

    def set_plugin_hooks
      @before_up_run_plugin   = :before_migration_up
      @after_up_run_plugin    = :after_migration_up
      @before_down_run_plugin = :before_migration_down
      @after_down_run_plugin  = :after_migration_down
      @before_running_plugin  = :before_running_migrations
      @after_running_plugin   = :after_running_migrations
    end

    
    def ensure_initialized
      @base.ensure_initialized
    end

    def connection
      @base.connection
    end
        
    
  end
end
