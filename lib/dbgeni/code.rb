module DBGeni
  class Code

    attr_reader :directory, :filename, :type, :name, :logfile, :error_messages
    PACKAGE_SPEC = 'PACKAGE SPEC'
    PACKAGE_BODY = 'PACKAGE BODY'
    PROCEDURE    = 'PROCEDURE'
    FUNCTION     = 'FUNCTION'
    TRIGGER      = 'TRIGGER'

    APPLIED = 'Applied'

    EXT_MAP = {
               'pks' => PACKAGE_SPEC,
               'pkb' => PACKAGE_BODY,
               'prc' => PROCEDURE,
               'fnc' => FUNCTION,
               'trg' => TRIGGER
    }

    def initialize(directory, filename)
      @directory = directory
      @filename  = filename
      set_type
      set_name
    end

    def db_hash(config, connection)
      results = connection.execute("select sequence_or_hash
                                    from #{config.db_table}
                                    where migration_name = :name
                                    and   migration_type = :type", @name, @type)
      results.length == 1 ? results[0][0] : nil
    end

    def hash
      # TODO what if file is empty?
      @hash ||= begin
                  hasher = Digest::SHA1.new
                  File.open(File.join(@directory, @filename), 'r') do |f|
                    Digest::SHA1.hexdigest(f.read())
                  end
                end
    end

    # if the DB hash equals the file hash then it is current
    def current?(config, connection)
      hash == nil_to_s(db_hash(config, connection))
    end

    # if a hash is found in the DB then it is applied.
    def applied?(config, connection)
      db_hash(config, connection) ? true : false
    end

    # If there is no db_hash then its outstanding.
    def outstanding?(config, connection)
      db_hash(config, connection) ? false : true
    end

    def set_applied(config, connection)
      env(config, connection)
      insert_or_set_state(APPLIED)
    end

    def set_removed(config, connection)
      env(config, connection)
      remove_db_record
    end

    def apply!(config, connection, force=false)
      env(config, connection)
      ensure_file_exists
      if current?(config, connection) and force != true
        raise DBGeni::CodeModuleCurrent, self.to_s
      end
      migrator = DBGeni::Migrator.initialize(config, connection)
      begin
        migrator.compile(self) #, force)
        set_applied(config,connection)
      rescue Exception => e
        raise DBGeni::CodeApplyFailed, "(#{self.to_s}) #{e.to_s}"
      end
      @logfile = migrator.logfile
      @error_messages = migrator.code_errors
    end

    def remove!(config, connection)
    end

#    def set_updated(config, connection)
#      env(config, connection)
#      remove_db_record
#    end

    def to_s
      "#{@name} - #{@type}"
    end


    private

#    def existing_db_record
#      results = @connection.execute("select sequence_or_hash, migration_name, migration_type, migration_state, start_dtm, completed_dtm
#                                    from #{@config.db_table}
#                                    where migration_name = :name
#                                    and   migration_type = :type", @name, @type)
#    end

    def insert_or_set_state(state)
      # no hash in the DB means there is no db record...
      results = db_hash(@config, @connection)
      if results == nil then
        add_db_record(state)
      else
        update_db_record(state)
      end
    end


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
                                       :hash,
                                       :name,
                                       :type,
                                       :state,
                                       #{@connection.date_placeholder('sdtm')}
                                    )", hash, @name, @type, state, @connection.date_as_string(Time.now))
    end


    def update_db_record(state)
      results = @connection.execute("update #{@config.db_table}
                                    set sequence_or_hash  = :hash,
                                        completed_dtm     = #{@connection.date_placeholder('sdtm')},
                                        migration_state   = :state
                                    where migration_type  = :type
                                    and   migration_name  = :name", hash, @connection.date_as_string(Time.now), state, @type, @name)
    end


    def remove_db_record
      results = @connection.execute("delete from #{@config.db_table}
                                    where migration_type  = :type
                                    and   migration_name  = :name", @type, @name)
    end

    def set_type
      @filename =~ /\.(.+)$/
      if EXT_MAP.has_key?($1)
        @type = EXT_MAP[$1]
      else
        raise DBGeni::UnknownCodeType, $1
      end
    end

    def set_name
      @filename =~ /^(.+)\.[a-z]{3}$/
      @name = $1.upcase
    end

    def env(config, connection)
      @config     = config
      @connection = connection
    end

    def ensure_file_exists
      unless File.exists? File.join(@directory, @filename)
        raise DBGeni::CodeFileNotExist, File.join(@directory, @filename)
      end
    end

    def nil_to_s(obj)
      obj ? obj : ''
    end
  end
end
