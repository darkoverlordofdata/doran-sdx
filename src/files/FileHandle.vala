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
namespace Sdx.Files {

	/**
	 * get a better grip on the file object
	 */	
	public class FileHandle : Object {
		private Utils.File file;
		private string path;
		private FileType type;

		public FileHandle(string path, FileType type) {
			this.type = type;
			this.path = path;
			this.file = new Utils.File(path);
		}

		/**
		 * Loads a raw resource value
		 */
		public SDL.RWops getRWops() {
			if (type == FileType.Resource) {
#if (ANDROID || EMSCRIPTEN || NOGOBJECT)
				throw new SdlException.InvalidForPlatform("Resource not available");
#else
				var path = getPath().Replace("\\", "/");

                if (path[path.length-1] == (char)13)
                    path = path.SubString(0, path.length-1);
				var bytes = GLib.ResourcesLookupData(Sdx.resourceBase + "/" + path, 0);
                var raw = new SDL.RWops.FromMem((void*)bytes.GetData(), (int)bytes.GetSize());
                if (raw == null)
					throw new SdlException.UnableToLoadResource(getPath());
                return raw;
#endif				
			} else {
                var raw = new SDL.RWops.FromFile(getPath(), "r");
				if (raw == null)
					throw new SdlException.UnableToLoadResource(getPath());
                return raw;

			}
		}

		public string read() {
			if (type == FileType.Resource) {
#if (ANDROID || EMSCRIPTEN || NOGOBJECT)
				throw new SdlException.InvalidForPlatform("Resource not available");
#else
				var path = getPath().Replace("\\", "/");

                if (path[path.length-1] == (char)13)
                    path = path.SubString(0, path.length-1);
                var st =  GLib.ResourcesOpenStream(Sdx.resourceBase + "/" + path, 0);
				var sb = new StringBuilder();
				var ready = true;
				var buffer = new uint8[100];
				while (ready) {
					var size = st.Read(buffer);
					if (size > 0) {
						buffer[size] = 0;
						sb.Append((string) buffer);
					} else {
						ready = false;
					}
				}
				return sb.str;
#endif
			} else {
				return file.read();
			}
		}

		public FileType getType() {
			return type;
		}

		public string getName() {
			return file.getName();
		}

		public string getExt() {
            var name = getName();
            var i = name.LastIndexOf(".");
            if (i < 0) return "";
			var ext = name.SubString(i);
			// BUG fix for emscripten:
			if (ext.IndexOf(".") < 0) ext = "."+ext;
			return ext;
		}

		public string getPath() {
			return file.getPath();
		}

		public FileHandle getParent() {
			return new FileHandle(file.getParent(), type); //FileType.Parent);
		}

		public bool exists() {
			if (type == FileType.Resource) {
				return true;
			} else {
				return file.exists();
			}
		}

		/**
		 * Gets a file that is a sibling
		 */
		public FileHandle child(string name) {
            return new FileHandle(file.getPath() + Utils.PathSeparator + name, type);
		}

	}
}


