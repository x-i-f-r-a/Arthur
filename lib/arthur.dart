import 'dart:async';
import 'dart:ffi';
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';
import 'package:postgres/postgres.dart';

abstract class Arthur {

  String? tableName;
  String? db;
  String? dbName;
  String? host;
  int? port;
  String? username;
  String? password;

  
  Arthur({this.db = 'sqlite', this.tableName, this.dbName, this.host, this.username, this.port, this.password});


  Map<String, dynamic> toMap();

  FutureOr save() async {

    final fields = toMap();
    
    if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();

      var columns = fields.keys.skip(1).join(', ');
      var keys = fields.keys.skip(1).map((key) => fields[key] is Int ? '${fields[key]}' : '"${fields[key]}"').join(', ');
      var sql = 'INSERT INTO $tableName ($columns) VALUES (${keys.replaceAll('"', "'")});';
 
      try{
       await conn.query(sql);
       await conn.close();
      } on PostgreSQLException catch(e){
        print(e.message);
      }
    }else{

      final database = sqlite3.open('${Directory.current.path}/$dbName.db');

      var columns = fields.keys.skip(1).join(', ');

      var keys = fields.keys.skip(1).map((key) => fields[key] is Int ? '${fields[key]}' : '"${fields[key]}"').join(', ');
      var sql = 'INSERT INTO $tableName ($columns) VALUES (${keys.replaceAll('"', "'")});';

      try{
        database.execute(sql);
        database.dispose();
      } on SqliteException catch(e){
        print(e);
      }
    }
  }


  FutureOr getAll() async {

    if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();
      var data =  await conn.query('SELECT * FROM $tableName;');
      conn.close();
      
      return data;
      
    }else{
      final database = sqlite3.open('${Directory.current.path}/$dbName.db');
      
      return database.select('SELECT * FROM $tableName;');
    }

  }


  Future clear() async {

     if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();
      await conn.query('DELETE FROM $tableName;');
      conn.close();
      
      
    }else{

      final database = sqlite3.open('${Directory.current.path}/$dbName.db');

      database.execute('DELETE FROM $tableName');

    }

  }


  Future drop() async {
     if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();
      await conn.query('DROP TABLE $tableName;');
      conn.close();
      
      
    }else{

      final database = sqlite3.open('${Directory.current.path}/$dbName.db');
      
      database.execute('DROP TABLE $tableName');
    }
  }


  FutureOr getById(String idFieldName, int id) async {

    if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();
      final data = await conn.query('SELECT * FROM $tableName WHERE $idFieldName = $id');
      conn.close();
      return data;
      
      
    }else{

      final database = sqlite3.open('${Directory.current.path}/$dbName.db');
      
      return database.select('SELECT * FROM $tableName WHERE $idFieldName = $id');
    }
  }

  FutureOr deleteById(String idFieldName, int id) async {

    if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();
      await conn.query('DELETE FROM $tableName WHERE $idFieldName = $id');
      conn.close();
      
      
    }else{

      final database = sqlite3.open('${Directory.current.path}/$dbName.db');
      
      database.execute('DELETE FROM $tableName WHERE $idFieldName = $id');
    }
  }

  FutureOr execRaw(String sql) async {

    if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();
      await conn.query(sql);
      conn.close();
      
      
    }else{

      final database = sqlite3.open('${Directory.current.path}/$dbName.db');
      
      if(sql.startsWith('SELECT')){
        database.select(sql);
      }else{
        database.execute(sql);
      }
    }
  }

  Future count() async {

    if(db == 'postgres'){
      final conn =  PostgreSQLConnection(
        host!,
        port!, 
        dbName!,
        username: username!,
        password: password!);
      await conn.open();
      final count = await conn.query('SELECT COUNT(*) FROM $tableName');
      conn.close();

      return count[0][0] as int;
      
      
    }else{

      final database = sqlite3.open('${Directory.current.path}/$dbName.db');
      final count = database.select('SELECT COUNT(*) FROM $tableName');

      return count.first.columnAt(0) as int;
    }
  }
}