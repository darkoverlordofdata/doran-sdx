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
/**
 * Sdx Graphics
 * 
 * 2D Sprites, Texts, and Images
 */
namespace Sdx.Graphics { 

	/**
	 * Simple blit parameters
	 */
	public struct Blit {
		SDL.Video.Rect source;
		SDL.Video.Rect dest;
		SDL.Video.RendererFlip flip;
	}
	
	public delegate Blit[] Compositor(int x, int y);	
    
}