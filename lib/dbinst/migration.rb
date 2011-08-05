module DBInst

  class Migration

    attr_reader :migration_file, :name, :sequence

    def initialize(directory, migration)
      @directory      = directory
      @migration_file = migration
      parse_file
    end

    def rollbackable?
    end

    def verifyable?
    end

    def rollback_file
    end

    def verify_file
    end

    def applied?(environment)
    end

    def apply!(environment)
    end

    def rollback!(environment)
    end

    def verify!(environment)
    end

    private

    def parse_file
      # filename is made up of 3 parts
      # Sequence - YYYYMMDDHH(24)MI - ie datestamp down to minute
      # Operation - allowed are up, down, verify
      # Migration_name - any amount of text
      # eg
      #     201107011644_up_my_shiny_new_table.sql
      #
      unless @migration_file =~ /^(\d{12})_up_(.+)\.sql$/
        raise DBInst::MigrationFilenameInvalid
      end
      @sequence = $1
      @name     = $2
    end

  end

end
