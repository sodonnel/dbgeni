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
      @migrations.select {|m| m.applied?(config, connection) }.sort {|x,y| x.migration_file <=> y.migration_file }
    end

    def outstanding(config, connection)
      migrations.reject {|m| m.applied?(config, connection) }.sort {|x,y| x.migration_file <=> y.migration_file }
    end

    def broken(config, connection)
      @migrations.select {|m| [DBGeni::Migration::FAILED, DBGeni::Migration::PENDING].include? m.status(config, connection) }.sort {|x,y| x.migration_file <=> y.migration_file }
    end

    def applied_and_broken(config, connection)
      a = applied(config, connection)
      b = broken(config, connection)
      a.concat b
      a.uniq{|m| m.migration_file }.sort {|x,y| x.migration_file <=> y.migration_file }
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
