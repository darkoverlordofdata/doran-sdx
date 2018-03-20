/* ******************************************************************************
 * Copyright 2017 darkoverlordofdata.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/
namespace Sdx.Utils {

    /**
     * Simple Json Parser
     * 
     * based on JSON.parse
     * 
     * by [[Crockford]] [[https://github.com/douglascrockford/JSON-js]]
     */
    public errordomain JsonException {
        SyntaxError,
        UnexpectedCharacter,
        InvalidString,
        InvalidArray,
        InvalidObject,
        DuplicateKey
    }

    public enum JsType {
        JS_INVALID,
        JS_BOOLEAN,
        JS_NUMBER,
        JS_STRING,
        JS_OBJECT,
        JS_ARRAY
    }

    public delegate JsVariant JsDelegate(JsVariant holder, string key, JsVariant value);

    public class Json : Object {

        public static const string HEX_DIGIT = "0123456789abcdef";
        public static const string escape0 = "\"\\/bfnrt";
        public static const string[] escape1 = {"\"", "\\", "/", "\b", "\f", "\n", "\r", "\t"};
        public static string gap;
        public static string indent;
        
        private int at;
        private char ch;
        private string text;
        private JsDelegate _replacer;


        public Json(JsDelegate replacer = null) {
            _replacer = replacer;
        }

        public static JsVariant parse(string source) {
            return new Json().parseJson(source);
        }

        public static string stringify(JsVariant value, JsDelegate replacer = null, string space = "") {
            // The stringify method takes a value and an optional Replacer, and an optional
            // space parameter, and returns a JSON text. The Replacer can be a function
            // that can replace values, or an array of strings that will select the keys.
            // A default Replacer method can be provided. Use of the space parameter can
            // produce text that is more easily readable.

            gap = "";
            indent = space;

            var holder = new JsVariant(JsType.JS_OBJECT);
            holder.object.Set("", value);
            return new Json(replacer).str("", holder);
        }

        public string quote(string str) {
            return "\"" + str + "\"";
        }

        public JsVariant getItem(JsVariant holder, string key) {
            switch (holder.type) {
                case JsType.JS_ARRAY:
                    return holder.array.Item(int.Parse(key)).data;
                case JsType.JS_OBJECT:
                    return holder.object.Get(key);
                default:
                    return null;
            }
        }

        public string str(string key, JsVariant holder) {
            // Produce a string from holder[key].

            var length = 0;
            var mind = gap;
            JsVariant value = getItem(holder, key);

            if (_replacer != null) {
                value = _replacer(holder, key, value);
            }

            switch (value.type) {

                case JsType.JS_STRING:
                    return quote(value.string);

                case JsType.JS_NUMBER:
                    return value.number.ToString(); 

                case JsType.JS_BOOLEAN:
                    return value.boolean.ToString();

                case JsType.JS_OBJECT:
                    if (value.object == null) return "null";
                    gap += indent;
                    length = (int)value.object.Size();
                    var partial = new string[length];

                    // iterate through all of the keys in the object.
                    var keys = value.object.GetKeysAsArray();
                    for (var i = 0; i < keys.length; i++) {
                        var k = keys[i];
                        partial[i] = quote(k) + (gap.length>0 ? ": " : ":") + str(k, value);
                    }
                    // Join all of the member texts together, separated with commas,
                    // and wrap them in braces.
                    var v = "";
                    if (partial.length == 0) {
                        v =  "{}";
                    } else if (gap.length > 0) {
                        v = "{\n" + gap + string.Joinv(",\n" + gap, partial) + "\n" + mind + "}";
                    } else {
                        v = "{" + string.Joinv(",", partial) + "}";
                    }
                    gap = mind;
                    return v;
                    

                case JsType.JS_ARRAY:
                    if (value.array == null) return "null";
                    gap += indent;
                    
                    // The value is an array. Stringify every element                    
                    length = (int)value.array.Length();
                    var partial = new string[length];
                    for (var i = 0; i < length; i++) {
                        partial[i] = str(i.ToString(), value);
                    }
                    // Join all of the elements together, separated with commas, and wrap them in
                    // brackets.

                    var v = "";
                    if (partial.length == 0) {
                        v =  "[]";
                    } else if (gap.length > 0) {
                        v = "[\n" + gap + string.Joinv(",\n" + gap, partial) + "\n" + mind + "]";
                    } else {
                        v = "[" + string.Joinv(",", partial) + "]";
                    }
                    gap = mind;
                    return v;
            }
            return "";
        }

        public JsVariant parseJson(string source) {

            text = source;
            at = 0;
            ch = ' ';
            var result = getValue();
            skipWhite();
            if (ch != 0) {
                throw new JsonException.SyntaxError("");
            }
            return result;
        }

        public char next(char? c=null) 
        {
            // If a c parameter is provided, verify that it matches the current character.
            if (c != null && c != ch) 
            {
                throw new JsonException.UnexpectedCharacter("Expected '%s' instead of '%s'", c.ToString(), ch.ToString());
            }
            // Get the next character. When there are no more characters,
            // return the empty string.
            ch = text[at];
            at += 1;
            return ch;
        }

        public JsVariant getValue() 
        {

            // Parse a JSON value. It could be an object, an array, a string, a number,
            // or a word.

            skipWhite();
            switch (ch) {
                case '{':
                    return getObject();
                case '[':
                    return getArray();
                case '\"':
                    return getString();
                case '-':
                    return getNumber();
                default:
                    return (ch >= '0' && ch <= '9')
                        ? getNumber()
                        : getWord();
            }
        }

        public JsVariant getNumber() {
            // Parse a number value.
            var string = "";

            if (ch == '-') {
                string = "-";
                next('-');
            }

            while (ch >= '0' && ch <= '9') {
                string += ch.ToString();
                next();
            }
            if (ch == '.') {
                string += ".";
                while (next() != 0 && ch >= '0' && ch <= '9') {
                    string += ch.ToString();
                }
            }
            if (ch == 'e' || ch == 'E') {
                string += ch.ToString();
                next();
                if (ch == '-' || ch == '+') {
                    string += ch.ToString();
                    next();
                }
                while (ch >= '0' && ch <= '9') {
                    string += ch.ToString();
                    next();
                }
            }
            return JsVariant.Number((double)double.Parse(string));
        }

        public JsVariant getString() {
            // Parse a string value.
            var hex = 0;
            var i = 0;
            var string = "";
            var uffff = 0;
            // When parsing for string values, we must look for " and \ characters.

            if (ch == '\"') {
                while (next() != 0) {
                    if (ch == '\"') {
                        next();
                        return JsVariant.String(string);
                    }
                    if (ch == '\\') {
                        next();
                        if (ch == 'u') {
                            uffff = 0;
                            for (i = 0; i < 4; i += 1) {
                                hex = HEX_DIGIT.IndexOf(next().ToString().down());
                                if (hex < 0) break;
                                uffff = uffff * 16 + hex;
                            }
                            string += ((char)uffff).ToString();
                        } else if ((i = escape0.IndexOf(ch.ToString())) >= 0) {
                            string += escape1[i];
                        } else {
                            break;
                        }
                    } else {
                        string += ch.ToString();
                    }
                }
            }
            throw new JsonException.InvalidString("");
        }


        public void skipWhite() {

            // Skip whitespace.

            while (ch != 0 && ch <= ' ') {
                next();
            }
        }

        public JsVariant getWord() {

            switch (ch) {
                case 't':
                    next('t');
                    next('r');
                    next('u');
                    next('e');
                    return JsVariant.Boolean(true);
                case 'f':
                    next('f');
                    next('a');
                    next('l');
                    next('s');
                    next('e');
                    return JsVariant.Boolean(false);
                case 'n':
                    next('n');
                    next('u');
                    next('l');
                    next('l');
                    return new JsVariant(JsType.JS_OBJECT, true);
            }
            throw new JsonException.UnexpectedCharacter("Unexpected '%s'", ch.ToString());

        }

        public JsVariant getArray() {
            // Parse an array value.
            var result = new JsVariant(JsType.JS_ARRAY);

            if (ch == '[') {
                next('[');
                skipWhite();
                if (ch == ']') {
                    next(']');
                    return result;
                }
                while (ch != 0) {
                    result.array.Add(getValue());
                    skipWhite();
                    if (ch == ']') {
                        next(']');
                        return result;
                    }
                    next(',');
                    skipWhite();
                }
            }
            throw new JsonException.InvalidArray("");
        }

        public JsVariant getObject() {
            // Parse an object value.
            var key = "";
            var result = new JsVariant(JsType.JS_OBJECT);

            if (ch == '{') {
                next('{');
                skipWhite();
                if (ch == '}') {
                    next('}');
                    return result;
                }
                while (ch != 0) {
                    key = getString().string;
                    skipWhite();
                    next(':');
                    if (result.object.Contains(key)) {
                        throw new JsonException.DuplicateKey("");
                    }
                    result.object.Set(key, getValue());
                    skipWhite();
                    if (ch == '}') {
                        next('}');
                        return result;
                    }
                    next(',');
                    skipWhite();
                }
            }
            throw new JsonException.InvalidObject("");

        }

    }
    /**
     * Wrap a Json object
     * 
     * Arrays are represented as List<JsVariant>
     * Objects are represented as HashTable<string, JsVariant>
     */
    public class JsVariant : Object {

        public bool boolean;
        public double number;
        public string string;
        public HashTable<string, JsVariant> object;
        public List<JsVariant> array;

        public JsType type;

        public static JsVariant String(string value) {
            var it = new JsVariant(JsType.JS_STRING);
            it.string = value;
            return it;
        }

        public static JsVariant Number(double value) {
            var it = new JsVariant(JsType.JS_NUMBER);
            it.number = value;
            return it;
        }

        public static JsVariant Boolean(bool value) {
            var it = new JsVariant(JsType.JS_BOOLEAN);
            it.boolean = value;
            return it;
        }

        public JsVariant(JsType type, bool isNull = false) {
            this.type = type;
            switch (type) {
                case JsType.JS_BOOLEAN:
                    boolean = false;
                    break;
                case JsType.JS_NUMBER:
                    number = 0;
                    break;
                case JsType.JS_STRING:
                    string = "";
                    break;
                case JsType.JS_OBJECT:
                    object = isNull ? null : new HashTable<string, JsVariant>(str_hash, str_equal);
                    break;
                case JsType.JS_ARRAY:
                    array = new List<JsVariant>();
                    break;
                    
                default:
                    break;
            }
        }

        public JsVariant at(int index) {
            return array.Head.data;
        }

        //  public JsVariant member(string key) {
        //      return object.Get(key);
        //  }

        public JsVariant get(string key) {
            return object.Get(key);
        }
    }   
}

