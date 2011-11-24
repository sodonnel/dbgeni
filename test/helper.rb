module TestHelper

  require 'dbgeni/connectors/sqlite'
  require 'dbgeni/connectors/oracle'
  require 'dbgeni/connectors/mysql'
  require 'fileutils'

  TEMP_DIR = File.expand_path(File.join(File.dirname(__FILE__), "temp"))
  SQLITE_DB_NAME  = 'sqlite.dbb'

  ORA_USER     = 'sodonnel'
  ORA_PASSWORD = 'sodonnel'
  ORA_DB       = 'local11gr2'

  MYSQL_USER     = 'sodonnel'
  MYSQL_PASSWORD = 'sodonnel'
  MYSQL_DB       = 'sodonnel'
  MYSQL_HOSTNAME = '127.0.0.1'
  MYSQL_PORT     = '3306'

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

  def helper_mysql_connection
    connection = DBGeni::Connector::Mysql.connect(MYSQL_USER, MYSQL_PASSWORD, MYSQL_DB, MYSQL_HOSTNAME, MYSQL_PORT)
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

  def helper_mysql_config
    config = DBGeni::Config.new.load("database_type 'mysql'
                                      environment('development') {
                                         username '#{MYSQL_USER}'
                                         password '#{MYSQL_PASSWORD}'
                                         database '#{MYSQL_DB}'
                                         hostname '#{MYSQL_HOSTNAME}'
                                         port     '#{MYSQL_PORT}'
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

  def helper_good_mysql_migration
    create_migration_files("select 1 + 1 from dual;")
  end

  def helper_bad_mysql_migration
    create_migration_files("gfgfgdsgsdg;")
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
      end;
      /", 'proc1.prc')
  end

  def helper_good_procedure_file_no_terminator
    create_procedure_file("create or replace procedure proc1
      as
      begin
         null;
      end;", 'proc1.prc')
  end


  def helper_mysql_good_procedure_file
    create_procedure_file("delimiter $$
      drop procedure if exists proc1$$
      create procedure proc1()
      begin
      end$$", 'proc1.prc')
  end

  def helper_mysql_bad_procedure_file
    # compile error as () is missing after proc name
    create_procedure_file("delimiter $$
      drop procedure if exists proc1$$
      create procedure proc1
      begin
      end$$", 'proc1.prc')
  end

  def helper_mysql_good_function_file
    # compile error as () is missing after proc name
    create_procedure_file("delimiter $$
      drop function if exists func1$$
      create function func1()
        returns int
      begin
        return 1;
      end$$
      delimiter ;", 'func1.fnc')
  end

  def helper_mysql_bad_function_file
    # compile error as () is missing after func name
    create_procedure_file("delimiter $$
      drop function if exists func1$$
      create function func1
        returns int
      begin
        return 1;
      end$$
      delimiter ;", 'func1.fnc')
  end

  def helper_mysql_good_trigger_file
    # compile error as () is missing after proc name
    create_procedure_file("delimiter $$
      drop trigger if exists trg1$$
      CREATE TRIGGER trg1 BEFORE INSERT ON foo
      FOR EACH ROW
      BEGIN
      END;$$
      delimiter ;", 'trg1.trg')
  end


  def helper_mysql_bad_trigger_file
    # compile error as () is missing after proc name
    create_procedure_file("delimiter $$
      drop trigger if exists trg1$$
      CREATE TRIGGER trg1 BEFORE INSERT ON foonothere
      FOR EACH ROW
      BEGIN
      END;$$
      delimiter ;", 'trg1.trg')
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
      end;
      /", 'trg1.trg')
  end

  def helper_good_package_spec_file
    create_procedure_file("create or replace package pkg1
      as
        procedure foobar;
      end;
      /", 'pkg1.pks')
    create_procedure_file("create or replace package body pkg1
      as
        procedure foobar
        is
        begin
          null;
        end;
      end;
      /", 'pkg1.pkb')
  end

  def helper_good_package_body_file
      create_procedure_file("create or replace package body pkg1
      as
        procedure foobar
        is
        begin
          null;
        end;
      end;
      /", 'pkg1.pkb')
  end

  def helper_bad_procedure_file
    create_procedure_file("create or replace procedure proc1
      as
      begin
         null -- compile error here
      end;
      /", 'proc1.prc')
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
