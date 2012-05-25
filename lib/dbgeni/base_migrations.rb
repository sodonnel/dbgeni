module DBGeni
  module BaseModules
    module Migrations

      # This module isn't much good on its own, but it is here purely to
      # break up the code in the Base class. This module should be included
      # into base for migrations to work correctly.

      # Querying

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

      # Applying

      def apply_all_migrations(force=nil)
        ensure_initialized
        migrations = outstanding_migrations
        if migrations.length == 0
          raise DBGeni::NoOutstandingMigrations
        end
        migrations.each do |m|
          apply_migration(m, force)
        end
      end

      def apply_next_migration(force=nil)
        ensure_initialized
        migrations = outstanding_migrations
        if migrations.length == 0
          raise DBGeni::NoOutstandingMigrations
        end
        apply_migration(migrations.first, force)
      end

      def apply_until_migration(migration_name, force=nil)
        ensure_initialized
        milestone = Migration.initialize_from_internal_name(@config.migration_directory, migration_name)
        outstanding = outstanding_migrations
        index = outstanding.index milestone
        unless index
          # milestone migration doesn't exist or is already applied.
          raise MigrationNotOutstanding, milestone.to_s
        end
        0.upto(index) do |i|
          apply_migration(outstanding[i], force)
        end
      end

      def apply_migration(migration, force=nil)
        ensure_initialized
        begin
          run_plugin(:before_migration_up, migration)
          migration.apply!(@config, connection, force)
          @logger.info "Applied #{migration.to_s}"
        rescue DBGeni::MigrationApplyFailed
          @logger.error "Failed #{migration.to_s}. Errors in #{migration.logfile}\n\n#{migration.error_messages}\n\n"
          raise DBGeni::MigrationApplyFailed, migration.to_s
        ensure
          run_plugin(:after_migration_up, migration)
        end
      end

      # rolling back

      def rollback_all_migrations(force=nil)
        ensure_initialized
        migrations = applied_and_broken_migrations.reverse
        if migrations.length == 0
          raise DBGeni::NoAppliedMigrations
        end
        migrations.each do |m|
          rollback_migration(m, force)
        end
      end

      def rollback_last_migration(force=nil)
        ensure_initialized
        migrations = applied_and_broken_migrations
        if migrations.length == 0
          raise DBGeni::NoAppliedMigrations
        end
        # the most recent one is at the end of the array!!
        rollback_migration(migrations.last, force)
      end

      def rollback_until_migration(migration_name, force=nil)
        ensure_initialized
        milestone = Migration.initialize_from_internal_name(@config.migration_directory, migration_name)
        applied = applied_and_broken_migrations.reverse
        index = applied.index milestone
        unless index
          # milestone migration doesn't exist or is already applied.
          raise DBGeni::MigrationNotApplied, milestone.to_s
        end
        # The minus 1 is taken off index as we don't want to rollback the specified migration
        0.upto(index-1) do |i|
          rollback_migration(applied[i], force)
        end
      end

      def rollback_migration(migration, force=nil)
        ensure_initialized
        begin
          migration.rollback!(@config, connection, force)
          @logger.info  "Rolledback #{migration.to_s}"
        rescue DBGeni::MigrationApplyFailed
          @logger.error "Failed #{migration.to_s}. Errors in #{migration.logfile}\n\n#{migration.error_messages}\n\n"
          raise DBGeni::MigrationApplyFailed, migration.to_s
        end
      end

    end
  end
end
