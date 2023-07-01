import 'dart:async';
import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:postgres/postgres.dart';

FutureOr createPostgresTable(
  Map fields,
  String tableName,
  String dbName,
  String host,
  int port,
  String username,
  String password,
) async {
  PostgreSQLConnection conn = PostgreSQLConnection(host, port, dbName,
      username: username, password: password);
  await conn.open();

  if (fields.length != 0) {
    var key = fields.keys.map((key) => '$key ${fields[key]}').join(', ');
    var startSql = 'CREATE TABLE IF NOT EXISTS $tableName ($key)';

    try {
      await conn.query(startSql);
      conn.close();
    } on PostgreSQLException catch (e) {
      print(e);
    }
  } else {
    print(
        '[ INFO ] Unknown error!! Please check the "model_definitions.yaml" file for any corrections.');
  }
}

FutureOr createSqliteTable(Map fields, String tableName, String dbName) async {
  final database = sqlite3.open('${Directory.current.path}/$dbName.db');
  if (fields.length != 0) {
    var keys = fields.keys.map((key) => '$key ${fields[key]}').join(', ');
    var startSql = 'CREATE TABLE IF NOT EXISTS $tableName ($keys);';
    try {
      database.execute(startSql);
      database.dispose();
    } on SqliteException catch (e) {
      print(e.message);
    }
  } else {
    print('Unknown error!!');
    exit(0);
  }
}

Future createMOdel(String dbType) async {
  final yamlFile = File(Directory.current.path + '/lib/model_definition.yaml');
  final yamlContent = yamlFile.readAsStringSync();
  final yamlMap = loadYaml(yamlContent) as List;

  for (var yamlItem in yamlMap) {
    final dbName = yamlItem['database'] as String;
    final className = yamlItem['class'] as String;
    var fields = yamlItem['fields'] as List<dynamic>;

    final yamlFile = File(Directory.current.path + '/lib/dbconf.yaml');
    final yamlContent = yamlFile.readAsStringSync();

    final yamlMap = loadYaml(yamlContent);

    final host = yamlMap['host'] as String;
    final username = yamlMap['username'] as String;
    final password = yamlMap['password'] as String;
    final port = yamlMap['port'] as int;

    final classCode = StringBuffer()
      ..writeln('import "package:arthur/arthur.dart";')
      ..writeln()
      ..writeln()
      ..writeln('class $className extends Arthur {')
      ..writeln();

    for (final field in fields) {
      var fieldName = field.keys.first;
      classCode.writeln('  dynamic $fieldName;');
    }

    classCode
      ..writeln()
      ..writeln('  $className({');

    for (final field in fields) {
      var fieldName = field.keys.first;
      classCode.writeln('    this.$fieldName,');
    }

    classCode..writeln('  }): super(');

    Map fieldsMap = {};

    for (var field in fields) {
      var fieldName = field.keys.first;
      List fieldTypeParams = field.values.first;

      if (fieldTypeParams.length == 2) {
        var dataType = fieldTypeParams[0];
        var extraParam = fieldTypeParams[1];

        fieldsMap[fieldName] = "$dataType $extraParam";
      } else {
        var dataType = fieldTypeParams[0];
        fieldsMap[fieldName] = "$dataType";
      }
    }

    if (dbType == 'postgres' || dbType == 'postgresql') {
      classCode
        ..writeln('       host: "$host",')
        ..writeln('       username: "$username", ')
        ..writeln('       password: "$password", ')
        ..writeln('       port: $port, ')
        ..writeln('       db: "postgres",')
        ..writeln('       dbName: "$dbName",')
        ..writeln('       tableName: "_$className"');
      await createPostgresTable(
          fieldsMap, "_$className", dbName, host, port, username, password);
      print('[ INFO ] Table created : _$className');
    } else {
      classCode
        ..writeln('       db: "sqlite",')
        ..writeln('       dbName: "$dbName",')
        ..writeln('       tableName: "_$className"');
      await createSqliteTable(fieldsMap, "_$className", dbName);
      print('[ INFO ] Table created : _$className');
    }

    classCode
      ..writeln()
      ..writeln('       );')
      ..writeln()
      ..writeln()
      ..writeln(' @override')
      ..writeln(' Map<String, dynamic> toMap(){')
      ..writeln()
      ..writeln('   final map = <String, dynamic>{};');

    for (final field in fields) {
      var fieldName = field.keys.first;
      classCode.writeln('   map["$fieldName"] = $fieldName;');
    }
    classCode
      ..writeln('')
      ..writeln('   return map;')
      ..writeln(' }')
      ..writeln();

    classCode..writeln('}');

    final outputFileName = '$className.dart';
    final outputFile = File(Directory.current.path + '/lib/' + outputFileName);
    outputFile.writeAsStringSync(classCode.toString());

    print('[ INFO ] Model $className generated successfully');
  }
}

void main(List<String> args) async {
  try {
    if (args[0] == 'help') {
      print('Arthur CLI \n');
      print('Available commands -');
      print(
          '"arthur createmodel <sqlite/postgres>" : To create model using "model_definition.yaml" file');
    } else if (args[0] == 'createmodel' && args[1] == 'postgres' ||
        args[1] == 'postgresql') {
      createMOdel('postgres');
    } else if (args[0] == 'createmodel' && args[1] == 'sqlite') {
      createMOdel('sqlite');
    } else {
      print('Arthur CLI \n');
      print('[ INFO ] Unknown command!!');
      print('[ INFO ] Use "arthur help" for showing available commands');
    }
  } on RangeError {
    print('Arthur CLI \n');
    print('[ INFO ] Use "arthur help" for showing available commands');
  }
}
