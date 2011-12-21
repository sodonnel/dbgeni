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

    attr_reader :directory, :migration_file, :rollback_file, :name, :sequence, :logfile, :error_messages

    def self.internal_name_from_filename(filename)
      filename =~ /^(\d{12})_(up|down)_(.+)\.sql$/
      "#{$1}::#{$3}"
    end

    def self.filename_from_internal_name(internal_name)
      internal_name =~ /^(\d{12})::(.+)$/
      "#{$1}_up_#{$2}.sql"
    end

    def self.initialize_from_internal_name(directory, name)
      self.new(directory, Migration.filename_from_internal_name(name))
    end

    def self.get_milestone_migration(directory, name)
      migration = ''
      begin
        f = File.open(File.join(directory,name), 'r')
        migration = f.readline.chomp
      rescue EOFError
      ensure
        f.close if f
      end
      unless migration =~ /^(\d{12})_(up|down)_(.+)\.sql$/
        raise DBGeni::MilestoneHasNoMigration, name
      end
      migration
    end

    def initialize(directory, migration)
      @directory      = directory
      @migration_file = migration
      parse_file
      @rollback_file  = "#{sequence}_down_#{name}.sql"
      @runnable_migration = nil
      @runnable_rollback  = nil
    end

    def migration_file(dir='up')
      "#{@sequence}_#{dir}_#{name}.sql"
    end

    def ==(other)
      if other.migration_file == @migration_file and other.directory == @directory
        true
      else
        false
      end
    end

    def applied?(config, connection)
      result = status(config, connection)
      result == COMPLETED ? true : false
    end

    def status(config, connection)
      set_env(config, connection)
      results = connection.execute("select migration_state
                                    from #{@config.db_table}
                                    where sequence_or_hash = ?
                                    and migration_name = ?", @sequence, @name)
      results.length == 1 ? results[0][0] : NEW
    end
    #"

    def apply!(config, connection, force=nil)
      set_env(config, connection)
      if applied?(config, connection) and force != true
        raise DBGeni::MigrationAlreadyApplied, self.to_s
      end
      ensure_file_exists
      migrator = DBGeni::Migrator.initialize(config, connection)
      convert_migration(config)
      set_pending!
      begin
        migrator.apply(self, force)
        set_completed!
      rescue Exception => e
        set_failed!
        raise DBGeni::MigrationApplyFailed, self.to_s
      ensure
        @logfile        = migrator.logfile
        @error_messages = migrator.migration_errors
      end
    end

    def rollback!(config, connection, force=nil)
      set_env(config, connection)
      if [NEW, ROLLEDBACK].include? status(config, connection) and force != true
        raise DBGeni::MigrationNotApplied, self.to_s
      end
      ensure_file_exists('down')
      migrator = DBGeni::Migrator.initialize(config, connection)
      convert_rollback(config)
      set_pending!
      begin
        migrator.rollback(self, force)
        set_rolledback!()
      rescue Exception => e
        set_failed!
        raise DBGeni::MigrationApplyFailed, self.to_s
      ensure
        @logfile        = migrator.logfile
        @error_messages = migrator.migration_errors
      end
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

    def convert_migration(config)
      @runnable_migration = FileConverter.convert(@directory, @migration_file, config)
    end

    def convert_rollback(config)
      @runnable_rollback = FileConverter.convert(@directory, @rollback_file, config)
    end


    def runnable_migration
      if @runnable_migration
        @runnable_migration
      else
        File.join(@directory, @migration_file)
      end
    end

    def runnable_rollback
      if @runnable_rollback
        @runnable_rollback
      else
        File.join(@directory, @rollback_file)
      end
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
      results = @connection.execute("select sequence_or_hash, migration_name, migration_type, migration_state, start_dtm, completed_dtm
                                    from #{@config.db_table}
                                    where sequence_or_hash = ?
                                    and migration_name = ?", @sequence, @name)
    end
#"

    def add_db_record(state)
      results = @connection.execute("insert into #{@config.db_table}
                                    (
                                       sequence_or_hash,
                                       migration_name,
                                       migration_type,
                                       migration_state,
                                       start_dtm
                                    )
                                    values
                                    (
                                       ?,
                                       ?,
                                       'Migration',
                                       ?,
                                       #{@connection.date_placeholder('sdtm')}
                                    )", @sequence, @name, state, @connection.date_as_string(Time.now))
    end


    def update_db_state(state)
      # What to set the dates to?  If going to PENDING, then you want to make
      # completed_dtm null and reset start_dtm to now.
      #
      # If going to anything else, then set completed_dtm to now
      if state == PENDING
        results = @connection.execute("update #{@config.db_table}
                                       set migration_state = ?,
                                           completed_dtm   = null,
                                           start_dtm       = #{@connection.date_placeholder('sdtm')}
                                       where sequence_or_hash = ?
                                    and   migration_name   = ?", state, @connection.date_as_string(Time.now), @sequence, @name)
      else
        results = @connection.execute("update #{@config.db_table}
                                    set migration_state = ?,
                                        completed_dtm   = #{@connection.date_placeholder('sdtm')}
                                    where sequence_or_hash = ?
                                    and   migration_name   = ?", state, @connection.date_as_string(Time.now), @sequence, @name)
      end
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
        raise DBGeni::MigrationFilenameInvalid, self.migration_file
      end
      @sequence = $1
      @name     = $2
    end

    def ensure_file_exists(dir='up')
      unless File.exists? File.join(@directory, self.migration_file(dir))
        raise DBGeni::MigrationFileNotExist, File.join(@directory, migration_file(dir))
      end
    end

  end

end
