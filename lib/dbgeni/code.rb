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
      @runnable_code = nil
      set_type
      set_name
    end

    def db_hash(config, connection)
      results = connection.execute("select sequence_or_hash
                                    from #{config.db_table}
                                    where migration_name = ?
                                    and   migration_type = ?", @name, @type)
      results.length == 1 ? results[0][0] : nil
    end
#" THis line i just to fix the bad syntax highlighting!

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
      convert_code(config)
      begin
        migrator.compile(self)
        set_applied(config,connection)
      rescue DBGeni::MigrationContainsErrors
        # MYSQL (and sybase is like mysql) and Oracle procedures are handled different.
        # In Oracle if the code fails to
        # compile, it can be because missing objects are not there, but in mysql the proc
        # will compile fine if objects are missing - the only reason it seems to not compile
        # is if the syntax is bad.
        # Also, an error loading mysql proc will result in the proc not being on the DB at all.
        # Can argue either way if DBGeni should stop on code errors. As many oracle compile errors
        # could be caused by objects that have not been created yet, best for Oracle to continue,
        # but for mysql I think it is best to stop.
        if migrator.class.to_s =~ /Oracle/
          @error_messages = migrator.migration_errors
        elsif migrator.class.to_s =~ /(Mysql|Sybase)/
          @error_messages = migrator.code_errors
        end
        unless force
          raise DBGeni::CodeApplyFailed
        end
      ensure
        @logfile = migrator.logfile
        # Only set this if it has not been set in the exception handler
        @error_messages ||= migrator.code_errors
      end
    end

    def remove!(config, connection, force=false)
      env(config, connection)
      ensure_file_exists
      migrator = DBGeni::Migrator.initialize(config, connection)
      begin
        migrator.remove(self)
        remove_db_record
      rescue Exception => e
        raise DBGeni::CodeRemoveFailed, e.to_s
      end
    end

    def to_s
      "#{@name} - #{@type}"
    end

    def convert_code(config)
      @runnable_code = FileConverter.convert(@directory, @filename, config)
    end

    def runnable_code
      if @runnable_code
        @runnable_code
      else
        File.join(@directory, @filename)
      end
    end

    private

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
                                       ?,
                                       ?,
                                       ?,
                                       ?,
                                       #{@connection.date_placeholder('sdtm')}
                                    )", hash, @name, @type, state, @connection.date_as_string(Time.now))
    end


    def update_db_record(state)
      results = @connection.execute("update #{@config.db_table}
                                    set sequence_or_hash  = ?,
                                        completed_dtm     = #{@connection.date_placeholder('sdtm')},
                                        migration_state   = ?
                                    where migration_type  = ?
                                    and   migration_name  = ?", hash, @connection.date_as_string(Time.now), state, @type, @name)
    end


    def remove_db_record
      results = @connection.execute("delete from #{@config.db_table}
                                    where migration_type  = ?
                                    and   migration_name  = ?", @type, @name)
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
