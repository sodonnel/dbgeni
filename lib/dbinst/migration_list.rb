module DBInst

  class MigrationList

    attr_reader :migrations
    attr_reader :migration_directory

    def initialize(migration_directory)
      @migration_directory = migration_directory
      file_list
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
        raise DBInst::MigrationDirectoryNotExist, "Migrations directory: #{@migrations_directory}"
      end
      @migrations = Array.new
      files.each do |f|
        @migrations.push Migration.new(@migration_directory, f)
      end
    end

  end

end
