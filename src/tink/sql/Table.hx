package tink.sql;

import tink.core.Any;
import tink.sql.Expr;
import tink.sql.Info;

#if macro
import haxe.macro.Expr;
using haxe.macro.Tools;
using tink.MacroApi;
#else
@:genericBuild(tink.sql.macros.TableBuilder.build())
class Table<T> {
}
#end

class TableSource<Fields, Filter:(Fields->Condition), Insert:{}, Row:Insert, Db> 
    extends Dataset<Fields, Filter, Row, Db> 
    implements TableInfo<Insert, Row> 
{
  
  public var name(default, null):TableName<Row>;

  @:noCompletion 
  public function getName()
    return name;
  
  function new(cnx, name, fields) {
    
    this.name = name;
    this.fields = fields;
    
    super(
      fields, 
      cnx, 
      TTable(name), 
      function (f:Filter) return (cast f : Fields->Condition)(fields) //TODO: raise issue on Haxe tracker and remove the cast once resolved
    );
  }
  
  public function insertMany(rows:Array<Insert>)
    return cnx.insert(this, rows);
    
  public function insertOne(row:Insert)
    return insertMany([row]);
  
  @:noCompletion 
  public function fieldnames()
    return Reflect.fields(fields);
  
  @:noCompletion 
  public function sqlizeRow(row:Insert, val:Any->String):Array<String> 
    return [for (f in fieldnames()) val(Reflect.field(row, f))];
    
  @:privateAccess
  macro public function init(e:Expr, rest:Array<Expr>) {
    return switch e.typeof().sure().follow() {
      case TInst(_.get() => { module: m, name: n }, _):
        e.assign('$m.$n'.instantiate(rest));
      default: e.reject();
    }
  }

}

abstract TableName<Row>(String) to String {
  public inline function new(s)
    this = s;
}