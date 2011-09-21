module DBGeni

  class MigrationList

    attr_reader :migrations
    attr_reader :migration_directory

    def initialize(migration_directory)
      @migration_directory = migration_directory
      file_list
    end

    # Returns an array of MIGRATIONS that have been applied
    # ordered by oldest first
    def applied(config, connection)
      migrations_with_status(config, connection, DBGeni::Migration::COMPLETED)
    end

    def outstanding(config, connection)
      migrations_with_status(config, connection,
                             DBGeni::Migration::NEW,
                             DBGeni::Migration::ROLLEDBACK,
                             DBGeni::Migration::FAILED,
                             DBGeni::Migration::PENDING)
    end

    def applied_and_broken(config, connection)
      migrations_with_status(config, connection,
                             DBGeni::Migration::COMPLETED,
                             DBGeni::Migration::FAILED,
                             DBGeni::Migration::PENDING)
    end

    def migrations_with_status(config, connection, *args)
      migrations = @migrations.select{|m|
        args.include? m.status(config, connection)
      }.sort {|x,y|
        x.migration_file <=> y.migration_file
      }
    end

    private

    def file_list
      begin
        # Migrations usually come in pairs, so need to find just the 'up'
        # ones here, otherwise there will be too many!
        # The migration filename format is YYYYMMDDHHMM_<up / down >_title.sql
        files = Dir.entries(@migration_directory).grep(/^\d{12}_up_.+\.sql$/).sort
      rescue Exception => e
        puts "Migrations directory: #{@migrations_directory}"
        raise DBGeni::MigrationDirectoryNotExist, "Migrations directory: #{@migrations_directory}"
      end
      @migrations = Array.new
      files.each do |f|
        @migrations.push Migration.new(@migration_directory, f)
      end
    end

  end

end
