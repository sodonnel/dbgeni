module DBGeni

  class Migration

    # These are all the states a migration can be in. The NEW status is never in the
    # database, as that is the default state when it has been created as a file,
    # but never applied to the database.
    #
    # PENDING - this is the state a migration goes into before the migration is runin
    #           and while it is running.
    # COMPLETED - after the migration completes, if it was successful it gets moved to this state
    # FAILED    - after the migration completes, if it failed it gets moved to this state
    # ROLLEDBACK - if a migration has been rolledback, it goes into this state.
    NEW         = 'New'
    PENDING     = 'Pending'
    FAILED      = 'Failed'
    COMPLETED   = 'Completed'
    ROLLEDBACK  = 'Rolledback'
    # TODO - add verified state?

    attr_reader :migration_file, :name, :sequence

    def initialize(directory, migration)
      @directory      = directory
      @migration_file = migration
      parse_file
    end

#    def rollback_file
#    end
#
#    def verify_file
#    end

    def applied?(config, connection)
      result = status(config, connection)
      result == COMPLETED ? true : false
    end

    def status(config, connection)
      set_env(config, connection)
      results = connection.execute("select migration_state
                                    from #{@config.db_table}
                                    where sequence_or_hash = :seq
                                    and migration_name = :migration", @sequence, @name)
      results.length == 1 ? results[0][0] : NEW
    end

    def apply!(config, connection)
    end

    def rollback!(config, connection)
    end

    def verify!(config, connection)
    end

    def set_pending(config, connection)
      set_env(config, connection)
      set_pending!
    end

    def set_completed(config, connection)
      set_env(config, connection)
      set_completed!
    end

    def set_failed(config, connection)
      set_env(config, connection)
      set_failed!
    end

    def set_rolledback(config, connection)
      set_env(config, connection)
      set_rolledback!
    end

    def to_s
      "#{@sequence}::#{@name}"
    end

    private

    def set_pending!
      insert_or_set_state(PENDING)
    end

    def set_completed!
      insert_or_set_state(COMPLETED)
    end

    def set_failed!
      insert_or_set_state(FAILED)
    end

    def set_rolledback!
      insert_or_set_state(ROLLEDBACK)
    end

    def set_env(config, connection)
      @config     = config
      @connection = connection
    end

    def insert_or_set_state(state)
      results = existing_db_record
      if results.length == 0 then
        add_db_record(state)
      else
        update_db_state(state)
      end
    end

    def existing_db_record
      results = @connection.execute("select sequence_or_hash, migration_name, migration_type, migration_state
                                    from #{@config.db_table}
                                    where sequence_or_hash = :seq
                                    and migration_name = :migration", @sequence, @name)
    end


    def add_db_record(state)
      results = @connection.execute("insert into #{@config.db_table}
                                    (
                                       sequence_or_hash,
                                       migration_name,
                                       migration_type,
                                       migration_state
                                    )
                                    values
                                    (
                                       :sequence,
                                       :name,
                                       'Migration',
                                       :state
                                    )", @sequence, @name, state)
    end


    def update_db_state(state)
      results = @connection.execute("update #{@config.db_table}
                                    set migration_state = :state
                                    where sequence_or_hash = :sequence
                                    and   migration_name   = :name", state, @sequence, @name)
    end


    def parse_file
      # filename is made up of 3 parts
      # Sequence - YYYYMMDDHH(24)MI - ie datestamp down to minute
      # Operation - allowed are up, down, verify
      # Migration_name - any amount of text
      # eg
      #     201107011644_up_my_shiny_new_table.sql
      #
      unless @migration_file =~ /^(\d{12})_up_(.+)\.sql$/
        raise DBGeni::MigrationFilenameInvalid
      end
      @sequence = $1
      @name     = $2
    end

  end

end
