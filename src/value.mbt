///|
pub enum Value {
  Null
  Bool(Bool)
  Int(Int)
  Float(Double)
  String(String)
  Array(Array[Value])
  Object(Map[String, Value])
  Safe(Value)
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

///|
pub fn from_json(json : Json) -> Value noraise {
  match json {
    Json::Null => Null
    Json::True => Bool(true)
    Json::False => Bool(false)
    Json::Number(num, ..) => {
      let int_part = num.to_int64()
      if int_part.to_double() == num {
        Int(int_part.to_int())
      } else {
        Float(num)
      }
    }
    Json::String(s) => String(s)
    Json::Array(arr) => {
      let values : Array[Value] = []
      for item in arr {
        values.push(from_json(item))
      }
      Array(values)
    }
    Json::Object(fields) => {
      let pairs = fields.to_array()
      let values : Array[(String, Value)] = []
      for pair in pairs {
        values.push((pair.0, from_json(pair.1)))
      }
      Object(Map::from_array(values))
    }
  }
}

///|
pub fn from_map(map : Map[String, Value]) -> Value noraise {
  Object(map)
}
