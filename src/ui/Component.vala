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
namespace Sdx.Ui {
	/**
	 * base UI Component
	 */
	public class Component : Object {
		public enum Kind {
			Window, Label, Button
        }
        public Kind kind;
        public Component? parent;
        public SDL.Video.Window? root;
        public SDL.Video.Rect? bounds;
        public SDL.Video.Color? foreground;
        public SDL.Video.Color? background;
        public Sdx.Font? font;
        public bool visible;
        public bool enabled;
        public bool valid;
        public string name;
        public bool focus;
        public bool selected;
        public string text;
        public List<Component> controls;
        public Sdx.Graphics.Sprite[] image;
        public int index;
        public InputProcessor handler;

        public delegate void ComponentOnMouseClick(Component c, int x, int y);
        public delegate void ComponentOnMouseLeave(Component c, int x, int y);
        public delegate void ComponentOnMouseEnter(Component c, int x, int y);
        public delegate void ComponentStart();
        public delegate void ComponentStop();
        public ComponentOnMouseClick onMouseClick = (c, x, y) => {};
        public ComponentOnMouseEnter onMouseEnter = (c, x, y) => {};
        public ComponentOnMouseLeave onMouseLeave = (c, x, y) => {};
        public ComponentStart start = () => {};
        public ComponentStart stop = () => {};

        public int width {
            get { return (int)bounds.w;}
        }
         
        public int height {
            get { return (int)bounds.h;}
        }

        public Component(int x=0, int y=0, int w=0, int h=0) {
            bounds = { x, y, w, h };
            visible = false;
            focus = true;
            controls = new List<Component>();
        }

        public void render(int x = 0, int y = 0) {
            x += bounds.x;
            y += bounds.y;

            if (index < image.length)
                image[index].Render(x, y);

            foreach (var child in controls) {
                child.render(x, y);
            }
        }

        public void add(Component child) {
            controls.Add(child);
            child.parent = this;
        }

        public void remove(Component child) {
            controls.Remove(child);
            child.stop();
            child.parent = null;
        }

        public Component setPos(int x, int y) {
            bounds.x = x;
            bounds.y = y;
            return this;
        }



    }
    public class Window : Component 
    {
        public Window(int w, int h, string name) 
        {
            base(0, 0, w, h);
            kind = Kind.Window;
            this.name = name;
            root = Sdx.initialize(w, h, name);
            Sdx.ui = this;
        }
    }

    /**
     * A Button is like a label with handler
     */
    public class Button : Component {
        public Button() {
            base();
            kind = Kind.Button;
            start = EventStart;
            stop = EventStop;
            start();
        }

        public void EventStop() {
            Sdx.removeInputProcessor(handler);
            handler = null;
        }

        public void EventStart() {
            Sdx.addInputProcessor(handler = new InputProcessor()

                .onTouchDown((x, y, pointer, button) => {
                    if (Test(x, y)) {
                        onMouseClick(this, x, y);
                        return true;
                    }
                    return false;
                })

                .onTouchUp((x, y, pointer, button) => {
                    return Test(x, y);
                })

                .onTouchDragged((x, y, pointer) => {
                    return Test(x, y);
                })
                
                .onMouseMoved((x, y) => {
                    return Test(x, y);
                })
            );
        }

        public bool Test(int x, int y)
        {
            var test = bounds.HasIntersection({ x, y, 1, 1 });
            if (test && index == 0) index = 1;
            if (!test && index == 1) index = 0;
            return test;
        }

        public class Text : Button {
            public Text(string text, Font font, SDL.Video.Color fg, SDL.Video.Color? bg = null) 
            {
                base();
                this.text = text;
                this.font = font;
                foreground = fg;
                background = bg;
                index = 0;
                image = { 
                    new Sdx.Graphics.Sprite.TextSprite(this.text, this.font, foreground, background) 
                };
                image[0].setCentered(false);
                bounds.w = image[0].width;
                bounds.h = image[0].height;
            }
        }

        public class NinePatch : Button {
            public NinePatch(string text, Font font, SDL.Video.Color fg, string img, string alt) 
            {
                base();
                this.text = text;
                this.font = font;
                foreground = fg;
                index = 0;
                image = { 
                    new Sdx.Graphics.Sprite.UISprite(Sdx.atlas.createPatch(img), this.text, this.font, foreground, 100, 40),
                    new Sdx.Graphics.Sprite.UISprite(Sdx.atlas.createPatch(alt), this.text, this.font, foreground, 100, 40) 
                };
                image[0].setCentered(false);
                image[1].setCentered(false);
                bounds.w = image[0].width;
                bounds.h = image[0].height;
            }
        }
    }
}


