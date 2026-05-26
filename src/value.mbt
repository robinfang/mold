///|
pub enum Value {
  Null
  Bool(Bool)
  Int(Int)
  Float(Double)
  String(String)
  Array(Array[Value])
  Object(Map[String, Value])
}

///|
pub fn null() -> Value noraise {
  Null
}

///|
pub fn bool(value : Bool) -> Value noraise {
  Bool(value)
}

///|
pub fn int(value : Int) -> Value noraise {
  Int(value)
}

///|
pub fn float(value : Double) -> Value noraise {
  Float(value)
}

///|
pub fn string(value : String) -> Value noraise {
  String(value)
}

///|
pub fn array(values : Array[Value]) -> Value noraise {
  Array(values)
}

///|
pub fn object(values : Map[String, Value]) -> Value noraise {
  Object(values)
}
