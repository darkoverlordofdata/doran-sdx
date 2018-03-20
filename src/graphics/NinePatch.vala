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
namespace Sdx.Graphics {
    /**
     * patch image
     * 
     */
    public class NinePatch : Object {
 

        private const int TOP_LEFT = 0;
        private const int TOP_CENTER = 1;
        private const int TOP_RIGHT = 2;
        private const int MIDDLE_LEFT = 3;
        private const int MIDDLE_CENTER = 4;
        private const int MIDDLE_RIGHT = 5;
        private const int BOTTOM_LEFT = 6;
        private const int BOTTOM_CENTER = 7;
        private const int BOTTOM_RIGHT = 8;

        public Surface.TextureSurface? texture;
        private int bottomLeft = -1;
        private int bottomCenter = -1;
        private int bottomRight = -1;
        private int middleLeft = -1;
        private int middleCenter = -1;
        private int middleRight = -1;
        private int topLeft = -1;
        private int topCenter = -1;
        private int topRight = -1;
        public int top;
        public int left;
        public int right;
        public int bottom;

        private float leftWidth;
        private float rightWidth;
        private float middleWidth;
        private float middleHeight;
        private float topHeight;
        private float bottomHeight;

        public Blit slice[9];
        private int idx;
        private SDL.Video.Color color = Color.White;
        private float padLeft = -1;
        private float padRight = -1;
        private float padTop = -1;
        private float padBottom = -1;

        private int sourceTop;
        private int sourceLeft;

        public NinePatch(TextureRegion region, int left, int right, int top, int bottom) {
            idx = 0;
            sourceTop = region.top;
            sourceLeft = region.left;
            this.top = top;
            this.left = left;
            this.right = right;
            this.bottom = bottom;
            if (region == null) throw new SdlException.IllegalArgumentException("region cannot be null.");
            var middleWidth = region.getRegionWidth() - left - right;
            var middleHeight = region.getRegionHeight() - top - bottom;

            var patches = new TextureRegion[9];
            if (top > 0) {
                if (left > 0) patches[TOP_LEFT] = new TextureRegion.FromRegion(region, 0, 0, left, top);
                if (middleWidth > 0) patches[TOP_CENTER] = new TextureRegion.FromRegion(region, left, 0, middleWidth, top);
                if (right > 0) patches[TOP_RIGHT] = new TextureRegion.FromRegion(region, left + middleWidth, 0, right, top);
            }
            if (middleHeight > 0) {
                if (left > 0) patches[MIDDLE_LEFT] = new TextureRegion.FromRegion(region, 0, top, left, middleHeight);
                if (middleWidth > 0) patches[MIDDLE_CENTER] = new TextureRegion.FromRegion(region, left, top, middleWidth, middleHeight);
                if (right > 0) patches[MIDDLE_RIGHT] = new TextureRegion.FromRegion(region, left + middleWidth, top, right, middleHeight);
            }
            if (bottom > 0) {
                if (left > 0) patches[BOTTOM_LEFT] = new TextureRegion.FromRegion(region, 0, top + middleHeight, left, bottom);
                if (middleWidth > 0) patches[BOTTOM_CENTER] = new TextureRegion.FromRegion(region, left, top + middleHeight, middleWidth, bottom);
                if (right > 0) patches[BOTTOM_RIGHT] = new TextureRegion.FromRegion(region, left + middleWidth, top + middleHeight, right, bottom);
            }

            // If split only vertical, move splits from right to center.
            if (left == 0 && middleWidth == 0) {
                patches[TOP_CENTER] = patches[TOP_RIGHT];
                patches[MIDDLE_CENTER] = patches[MIDDLE_RIGHT];
                patches[BOTTOM_CENTER] = patches[BOTTOM_RIGHT];
                patches[TOP_RIGHT] = null;
                patches[MIDDLE_RIGHT] = null;
                patches[BOTTOM_RIGHT] = null;
            }
            // If split only horizontal, move splits from bottom to center.
            if (top == 0 && middleHeight == 0) {
                patches[MIDDLE_LEFT] = patches[BOTTOM_LEFT];
                patches[MIDDLE_CENTER] = patches[BOTTOM_CENTER];
                patches[MIDDLE_RIGHT] = patches[BOTTOM_RIGHT];
                patches[BOTTOM_LEFT] = null;
                patches[BOTTOM_CENTER] = null;
                patches[BOTTOM_RIGHT] = null;
            }
            load(patches);
        }   

        private void load(TextureRegion[] patches) {
            var color = Color.White;

            if (patches[TOP_LEFT] != null) { 
                topLeft = add(patches[TOP_LEFT], color, false, false);
                leftWidth = (int)GLib.Math.fmax(leftWidth, patches[TOP_LEFT].getRegionWidth());
                topHeight = (int)GLib.Math.fmax(topHeight, patches[TOP_LEFT].getRegionHeight());
            }
            if (patches[TOP_CENTER] != null) { 
                topCenter = add(patches[TOP_CENTER], color, true, false);
                middleWidth = (int)GLib.Math.fmax(middleWidth, patches[TOP_CENTER].getRegionWidth());
                topHeight = (int)GLib.Math.fmax(topHeight, patches[TOP_CENTER].getRegionHeight());
            }
            if (patches[TOP_RIGHT] != null) { 
                topRight = add(patches[TOP_RIGHT], color, false, false);
                rightWidth = (int)GLib.Math.fmax(rightWidth, patches[TOP_RIGHT].getRegionWidth());
                topHeight = (int)GLib.Math.fmax(topHeight, patches[TOP_RIGHT].getRegionHeight());
            }
            if (patches[MIDDLE_LEFT] != null) { 
                middleLeft = add(patches[MIDDLE_LEFT], color, false, true);
                leftWidth = (int)GLib.Math.fmax(leftWidth, patches[MIDDLE_LEFT].getRegionWidth());
                middleHeight = (int)GLib.Math.fmax(middleHeight, patches[MIDDLE_LEFT].getRegionHeight());
            }            
            if (patches[MIDDLE_CENTER] != null) { 
                middleCenter = add(patches[MIDDLE_CENTER], color, true, true);
                middleWidth = (int)GLib.Math.fmax(middleWidth, patches[MIDDLE_CENTER].getRegionWidth());
                middleHeight = (int)GLib.Math.fmax(middleHeight, patches[MIDDLE_CENTER].getRegionHeight());
            }
            if (patches[MIDDLE_RIGHT] != null) { 
                middleRight = add(patches[MIDDLE_RIGHT], color, false, true);
                rightWidth = (int)GLib.Math.fmax(rightWidth, patches[MIDDLE_RIGHT].getRegionWidth());
                middleHeight = (int)GLib.Math.fmax(middleHeight, patches[MIDDLE_RIGHT].getRegionHeight());
            }
            if (patches[BOTTOM_LEFT] != null) {
                bottomLeft = add(patches[BOTTOM_LEFT], color, false, false);
                leftWidth = patches[BOTTOM_LEFT].getRegionWidth();
                bottomHeight = patches[BOTTOM_LEFT].getRegionHeight();
            }
            if (patches[BOTTOM_CENTER] != null) { 
                bottomCenter = add(patches[BOTTOM_CENTER], color, true, false);
                middleWidth = (int)GLib.Math.fmax(middleWidth, patches[BOTTOM_CENTER].getRegionWidth());
                bottomHeight = (int)GLib.Math.fmax(bottomHeight, patches[BOTTOM_CENTER].getRegionHeight());
            }
            if (patches[BOTTOM_RIGHT] != null) { 
                bottomRight = add(patches[BOTTOM_RIGHT], color, false, false);
                rightWidth = (int)GLib.Math.fmax(rightWidth, patches[BOTTOM_RIGHT].getRegionWidth());
                bottomHeight = (int)GLib.Math.fmax(bottomHeight, patches[BOTTOM_RIGHT].getRegionHeight());
            }
        }
            
        
        private int add(TextureRegion region, SDL.Video.Color color, bool isStretchW, bool isStretchH) {
            if (texture == null)
                texture = region.texture;
            else if (texture != region.texture) //
                throw new SdlException.IllegalArgumentException("All regions must be from the same texture.");

            var u = region.u;
            var v = region.v2;
            var u2 = region.u2;
            var v2 = region.v;

            // Add half pixel offsets on stretchable dimensions to acolor bleeding when GL_LINEAR
            // filtering is used for the texture. This nudges the texture coordinate to the center
            // of the texel where the neighboring pixel has 0% contribution in linear blending mode.
            if (isStretchW) {
                var halfTexelWidth = 0.5f * 1.0f / texture.width;
                u += halfTexelWidth;
                u2 -= halfTexelWidth;
            }
            
            if (isStretchH) {
                var halfTexelHeight = 0.5f * 1.0f / texture.height;
                v -= halfTexelHeight;
                v2 += halfTexelHeight;
            }

            slice[idx] = { 
                SDL.Video.Rect() { y = region.left + sourceLeft, x = region.top + sourceTop, w = region.width, h = region.height },
                SDL.Video.Rect() { y = region.left, x = region.top, w = region.width, h = region.height },
                0
            };

            return idx++;
        }
            
        public void setColor(SDL.Video.Color color) {
            this.color = color;
        }

        public SDL.Video.Color getColor() {
            return color;
        }

        public float getLeftWidth() { 
            return leftWidth;
        }

        /** 
         * Set the draw-time width of the three left edge patches 
         */
        public void setLeftWidth(float leftWidth) { 
            this.leftWidth = leftWidth;
        }

        public float getRightWidth() {
            return rightWidth;
        }

        /** 
         * Set the draw-time width of the three right edge patches 
         */
        public void setRightWidth(float rightWidth) { 
            this.rightWidth = rightWidth;
        }

        public float getTopHeight() {
            return topHeight;
        }

        /** 
         * Set the draw-time height of the three top edge patches 
         */
        public void setTopHeight(float topHeight) { 
            this.topHeight = topHeight;
        }

        public float getBottomHeight() {
            return bottomHeight;
        }

        /** 
         * Set the draw-time height of the three bottom edge patches 
         */
        public void setBottomHeight(float bottomHeight) { 
            this.bottomHeight = bottomHeight;
        }

        public float getMiddleWidth() {
            return middleWidth;
        }

        /** 
         * Set the width of the middle column of the patch. At render time, this is implicitly the requested render-width of the
         * entire nine patch, minus the left and right width. This value is only used for computing the link #GetTotalWidth() default
         * total width. 
         */
        public void setMiddleWidth(float middleWidth) { 
            this.middleWidth = middleWidth;
        }

        public float getMiddleHeight() {
            return middleHeight;
        }

        /** 
         * Set the height of the middle row of the patch. At render time, this is implicitly the requested render-height of the entire
         * nine patch, minus the top and bottom height. This value is only used for computing the link #GetTotalHeight() default
         * total height. 
         */
        public void setMiddleHeight(float middleHeight) { 
            this.middleHeight = middleHeight;
        }

        public float getTotalWidth() {
            return leftWidth + middleWidth + rightWidth;
        }

        public float getTotalHeight() {
            return topHeight + middleHeight + bottomHeight;
        }

        /** 
         * Set the padding for content inside this ninepatch. By default the padding is set to match the exterior of the ninepatch, so
         * the content should fit exactly within the middle patch. 
         */
        public void setPadding(float left, float right, float top, float bottom) { 
            this.padLeft = left;
            this.padRight = right;
            this.padTop = top;
            this.padBottom = bottom;
        }

        /** 
         * Returns the left padding if set, else returns link #GetLeftWidth(). 
         */
        public float getPadLeft() {
            if (padLeft == -1) return getLeftWidth();
            return padLeft;
        }

        /** 
         * See link #setPadding(float, float, float, float) 
         */
        public void setPadLeft(float left) { 
            this.padLeft = left;
        }

        /** 
         * Returns the right padding if set, else returns link #GetRightWidth(). 
         */
        public float getPadRight() {
            if (padRight == -1) return getRightWidth();
            return padRight;
        }

        /** 
         * See link #setPadding(float, float, float, float) 
         */
        public void setPadRight(float right) { 
            this.padRight = right;
        }

        /** 
         * Returns the top padding if set, else returns link #GetTopHeight(). 
         */
        public float getPadTop() {
            if (padTop == -1) return getTopHeight();
            return padTop;
        }

        /** 
         * See link #setPadding(float, float, float, float) 
         */
        public void setPadTop(float top) { 
            this.padTop = top;
        }

        /** 
         * Returns the bottom padding if set, else returns link #GetBottomHeight(). 
         */
        public float getPadBottom() {
            if (padBottom == -1) return getBottomHeight();
            return padBottom;
        }

        /** 
         * See link #setPadding(float, float, float, float) 
         */
        public void setPadBottom(float bottom) { 
            this.padBottom = bottom;
        }

        /** 
         * Multiplies the top/left/bottom/right sizes and padding by the specified amount. 
         */
        public void scale(float scaleX, float scaleY) { 
            leftWidth *= scaleX;
            rightWidth *= scaleX;
            topHeight *= scaleY;
            bottomHeight *= scaleY;
            middleWidth *= scaleX;
            middleHeight *= scaleY;
            if (padLeft != -1) padLeft *= scaleX;
            if (padRight != -1) padRight *= scaleX;
            if (padTop != -1) padTop *= scaleY;
            if (padBottom != -1) padBottom *= scaleY;
        }
    }
}