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
namespace Sdx {
	/** 
	 * An {@link InputProcessor} that delegates to an ordered list of other InputProcessors. Delegation for an event stops if a
	 * processor returns true, which indicates that the event was handled.
	 * based on code by  Nathan Sweet 
	 */
	public class InputMultiplexer : Object {
		public GenericArray<InputProcessor> processors;

		public InputMultiplexer() {
			processors = new GenericArray<InputProcessor>(4);
		}

		public void add(InputProcessor processor) {
			processors.Add(processor);
		}

		public void remove(InputProcessor processor) {
			processors.Remove(processor);
		}

		public bool keyDown(int keycode) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].keyDown(keycode)) return true;
			//  if (processors.Get(i).keyDown(keycode)) return true;
			return false;
		}

		public bool keyUp(int keycode) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].keyUp(keycode)) return true;
			return false;
		}

		public bool keyTyped(char character) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].keyTyped(character)) return true;
			return false;
		}

		public bool touchDown(int x, int y, int pointer, int button) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].touchDown(x, y, pointer, button)) return true;
			return false;
		}

		public bool touchUp(int x, int y, int pointer, int button) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].touchUp(x, y, pointer, button)) return true;
			return false;
		}

		public bool touchDragged(int x, int y, int pointer) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].touchDragged(x, y, pointer)) return true;
			return false;
		}

		public bool mouseMoved(int x, int y) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].mouseMoved(x, y)) return true;
			return false;
		}

		public bool scrolled(int amount) {
			for (var i=0; i<processors.length; i++)
				if (processors[i].scrolled(amount)) return true;
			return false;
		}
	}
}
