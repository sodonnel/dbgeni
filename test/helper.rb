module TestHelper

  require 'dbgeni/connectors/sqlite'
  require 'dbgeni/connectors/oracle'
  require 'fileutils'

  TEMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), "temp"))
  SQLITE_DB_NAME  = 'sqlite.db'

  ORA_USER     = 'sodonnel'
  ORA_PASSWORD = 'sodonnel'
  ORA_DB       = 'local11gr2'

  CLI = 'ruby C:\Users\sodonnel\code\dbgeni\lib\dbgeni\cli.rb'
#  CLI = 'ruby /home/sodonnel/code/dbgeni/lib/dbgeni/cli.rb'

  def helper_clean_temp
    FileUtils.rm_rf("#{TEMP_DIR}")
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'migrations'))
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'code'))
  end

  def helper_reinitialize_oracle
    conn   = helper_oracle_connection
    config = helper_oracle_config
    begin
      DBGeni::Initializer.initialize(conn, config)
      conn.initialize_database
    rescue DBGeni::DatabaseAlreadyInitialized
    end
    conn.execute("delete from dbgeni_migrations")
    begin
      conn.execute("drop procedure proc1")
    rescue
    end
    conn.disconnect
  end

  def helper_sqlite_connection
    FileUtils.mkdir_p(TEMP_DIR)
    FileUtils.rm_rf(File.join(TEMP_DIR, SQLITE_DB_NAME))
    connection = DBGeni::Connector::Sqlite.connect(nil, nil, "#{TEMP_DIR}/#{SQLITE_DB_NAME}")
  end

  def helper_sqlite_config
    config = DBGeni::Config.new.load("database_type 'sqlite'
                                      environment('development') {
                                         user     ''
                                         password ''
                                         database '#{TEMP_DIR}/#{SQLITE_DB_NAME}'
                                     }")
    config.base_directory = TEMP_DIR
    config
  end

  def helper_oracle_connection
    connection = DBGeni::Connector::Oracle.connect(ORA_USER, ORA_PASSWORD, ORA_DB)
  end

  def helper_oracle_config
    config = DBGeni::Config.new.load("database_type 'oracle'
                                      environment('development') {
                                         username '#{ORA_USER}'
                                         password '#{ORA_PASSWORD}'
                                         database '#{ORA_DB}'
                                     }")
    config.base_directory = TEMP_DIR
    config
  end

  def helper_sqlite_single_environment_file
    filename = "#{TEMP_DIR}/sqlite.conf"
    File.open(filename, 'w') do |f|
      f.puts "database_type 'sqlite'
                                      environment('development') {
                                         user     ''
                                         password ''
                                         database '#{TEMP_DIR}/#{SQLITE_DB_NAME}'
                                     }"
    end
    filename
  end

  def helper_sqlite_single_environment_file_with_errors
    filename = "#{TEMP_DIR}/sqlite.conf"
    File.open(filename, 'w') do |f|
      f.puts "database_typee 'sqlite'
                                      environment('development') {
                                         user     ''
                                         password ''
                                         database '#{TEMP_DIR}/#{SQLITE_DB_NAME}'
                                     }"
    end
    filename
  end



  def helper_sqlite_multiple_environment_file
    filename = "#{TEMP_DIR}/sqlite.conf"
    File.open(filename, 'w') do |f|
      f.puts "database_type 'sqlite'
                                      environment('development') {
                                         username ''
                                         password ''
                                         database '#{TEMP_DIR}/#{SQLITE_DB_NAME}'
                                     }"
      f.puts "                        environment('test') {
                                         username ''
                                         password ''
                                         database '#{TEMP_DIR}/#{SQLITE_DB_NAME}'
                                     }"
    end
    filename
  end

  def helper_oracle_single_environment_file
    filename = "#{TEMP_DIR}/oracle.conf"
    File.open(filename, 'w') do |f|
      f.puts "database_type 'oracle'
                                      environment('development') {
                                         username '#{ORA_USER}'
                                         password '#{ORA_PASSWORD}'
                                         database '#{ORA_DB}'
                                     }"
    end
    filename
  end


  def helper_good_oracle_migration
    create_migration_files("select * from dual;")
  end

  def helper_good_sqlite_migration
    create_migration_files("select * from sqlite_master;")
  end

  def helper_many_good_sqlite_migrations(number)
    datestamp = 201108190000 - 1
    1.upto(number) do
      datestamp += 1
      create_migration_files("select * from sqlite_master;", datestamp.to_s)
    end
  end

  def helper_many_bad_sqlite_migrations(number)
    datestamp = 201108190000 - 1
    1.upto(number) do
      datestamp += 1
      create_migration_files("select * from tab_not_exist;\ncreate table foo (c1 integer);", datestamp.to_s)
    end
  end


  def helper_bad_oracle_migration
    create_migration_files("select * from dua;\ncreate table foo (c1 integer);")
  end

  def helper_bad_sqlite_migration
    create_migration_files("select * from tab_not_exist;\ncreate table foo (c1 integer);")
  end

  def helper_empty_oracle_migration
    create_migration_files('')
  end

  def helper_empty_sqlite_migration
    helper_empty_oracle_migration
  end

  def helper_good_procedure_file
    create_procedure_file("create or replace procedure proc1
      as
      begin
         null;
      end;", 'proc1.prc')
  end

  def helper_good_function_file
    create_procedure_file("create or replace function func1
      return varchar2
      as
      begin
         null;
      end;", 'func1.fnc')
  end

  def helper_good_trigger_file
    create_procedure_file("create or replace trigger trg1
                           before insert on dbgeni_migrations
      begin
         null;
      end;", 'trg1.trg')
  end

  def helper_good_package_spec_file
    create_procedure_file("create or replace package pkg1
      as
        procedure foobar;
      end;", 'pkg1.pks')
    create_procedure_file("create or replace package body pkg1
      as
        procedure foobar
        is
        begin
          null;
        end;
      end;", 'pkg1.pkb')
  end

  def helper_good_package_body_file
      create_procedure_file("create or replace package body pkg1
      as
        procedure foobar
        is
        begin
          null;
        end;
      end;", 'pkg1.pkb')
  end

  def helper_bad_procedure_file
    create_procedure_file("create or replace procedure proc1
      as
      begin
         null -- compile error here
      end;", 'proc1.prc')
  end


  private

  def create_procedure_file(content, filename)
    FileUtils.rm_rf(File.join(TEMP_DIR, 'code', "*.*"))
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'code'))
    File.open(File.join(TEMP_DIR, 'code', filename), 'w') do |f|
      f.puts content
    end
    DBGeni::Code.new(File.join(TEMP_DIR, 'code'), filename)
  end

  def create_migration_files(content, datestamp='201108190000')
    FileUtils.rm_rf(File.join(TEMP_DIR, 'migrations', "*.sql"))
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'migrations'))
    filenames = ["#{datestamp}_up_test_migration.sql", "#{datestamp}_down_test_migration.sql"]
    filenames.each do |fn|
      File.open(File.join(TEMP_DIR, 'migrations', fn), 'w') do |f|
        f.puts content
      end
    end
    DBGeni::Migration.new(File.join(TEMP_DIR, 'migrations'), filenames[0])
  end

end
