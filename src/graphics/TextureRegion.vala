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
 * TextureRegion.gs
 *
 */
using GLib;
using Sdx.Graphics;

namespace Sdx.Graphics {

    public class TextureRegion : Object {
        internal Surface.TextureSurface? texture;
        public int top;
        public int left;
        public int width;
        public int height;
        private int regionWidth;
        private int regionHeight;
        public float u;
        public float v;
        public float u2;
        public float v2;

        /**
         * extra fields for use by subclass AtlasRegion
         * They need to be declared here because subclasses can't 
         * add fields.
         */
        public int index;
        /** 
         * The name of the original image file, up to the first underscore. Underscores denote special instructions to the texture
         * packer. 
         */
        public string name;
        /** 
         * The offset from the left of the original image to the left of the packed image, after whitespace was removed for packing. 
         */
        public int offsetX;
        /** 
         * The offset from the bottom of the original image to the bottom of the packed image, after whitespace was removed for
         * packing. 
         */
        public int offsetY;
        /** 
         * The width of the image, after whitespace was removed for packing. 
         */
        public int packedWidth;
        /** 
         * The height of the image, after whitespace was removed for packing. 
         */
        public int packedHeight;
        /** 
         * The width of the image, before whitespace was removed and rotation was applied for packing. 
         */
        public int originalWidth;
        /** 
         * The height of the image, before whitespace was removed for packing. 
         */
        public int originalHeight;
        /** 
         * If true, the region has been rotated 90 degrees counter clockwise. 
         */
        public bool rotate;
        /** 
         * The ninepatch splits, or null if not a ninepatch. Has 4 elements: left, right, top, bottom. 
         */
        public int[] splits;
        /** 
         * The ninepatch pads, or null if not a ninepatch or the has no padding. Has 4 elements: left, right, top, bottom. 
         */
        public int[] pads;

        public class FromTexture : TextureRegion {
            public FromTexture(Surface.TextureSurface texture, int x=0, int y=0, int width=0, int height=0) {
                width = width == 0 ? texture.width : width;
                height = height == 0 ? texture.height : height;
                this.texture = texture;
                this.top = x;
                this.left = y;
                this.width = width;
                this.height = height; 
                setRegionXY(x, y, width, height);
            }


        }
        public class FromRegion : TextureRegion {
            public FromRegion(TextureRegion region, int x=0, int y=0, int width=0, int height=0) {
                width = width == 0 ? region.texture.width : width;
                height = height == 0 ? region.texture.height : height;
                this.texture = region.texture;
                this.top = x;
                this.left = y;
                this.width = width;
                this.height = height; 
                setRegionXY(region.getRegionX() + x, region.getRegionY() + y, width, height);
            }


        }

        public void setRegion(float u, float v, float u2, float v2) {
            var texWidth = this.width;
            var texHeight = this.height;
            regionWidth =(int)GLib.Math.round(GLib.Math.fabs(u2 - u) * texWidth);
            regionHeight =(int)GLib.Math.round(GLib.Math.fabs(v2 - v) * texHeight);
            if (regionWidth == 1 && regionHeight == 1) {
                var adjustX = 0.25f / texWidth;
                u = adjustX;
                u2 = adjustX;
                var adjustY = 0.25f / texHeight;
                v = adjustY;
                v2 = adjustY;
            }
        }

        public void setRegionXY(int x, int y, int width, int height) {
            var invTexWidth = 1 / this.width;
            var invTexHeight = 1 / this.height;
            setRegion(x * invTexWidth, y * invTexHeight,(x + width) * invTexWidth,(y + height) * invTexHeight);
            regionWidth =(int)GLib.Math.fabs(width);
            regionHeight =(int)GLib.Math.fabs(height);
        }

        public void setByRegion(TextureRegion region) {
            texture = region.texture;
            setRegion(region.u, region.v, region.u2, region.v2);
        }

        public void setByRegionXY(TextureRegion region, int x, int y, int width, int height) {            
            texture = region.texture;
            setRegionXY(region.getRegionX()+x, region.getRegionY()+y, width, height);
        }

        public void flip(bool x, bool y) {
            if (x) {
                var temp = u;
                u = u2;
                u2 = temp;
            }
            if (y) {
                var temp = v;
                v = v2;
                v2 = temp;
            }
        }

        public float getU() { 
            return u;
        }

        public void setU(float u) { 
            this.u = u;
            regionWidth = (int)GLib.Math.round(GLib.Math.fabs(u2 - u) * this.width);
        }

        public float getV() {
            return v;
        }

        public void setV(float v) { 
            this.v = v;
            regionHeight = (int)GLib.Math.round(GLib.Math.fabs(v2 - v) * this.height);
        }

        public float getU2() {
            return u2;
        }

        public void setU2(float u2) { 
            this.u2 = u2;
            regionWidth = (int)GLib.Math.round(GLib.Math.fabs(u2 - u) * this.width);
        }

        public float getV2() {
            return v2;
        }

        public void setV2(float v2) { 
            this.v2 = v2;
            regionHeight = (int)GLib.Math.round(GLib.Math.fabs(v2 - v) * this.height);
        }

        public int getRegionX() {
            return (int)GLib.Math.round(u * this.width);
        }

        public void setRegionX(int x) {
            setU(x /(float)this.width);
        }

        public int getRegionY() {
            return (int)GLib.Math.round(v * this.height);
        }        

        public void setRegionY(int y) {
            setV(y /this.height);
        }

        /** 
         * Returns the region's width. 
         */
        public int getRegionWidth() {
            return regionWidth;
        }

        public void setRegionWidth(int width) {
            if (isFlipX())
                setU(u2 + width /(float)this.width);
             else 
                setU2(u + width /(float)this.width);
        }
        

        /** 
         * Returns the region's height. 
         */
        public int getRegionHeight() {
            return regionHeight;
        }

        public void setRegionHeight(int height) { 
            if (isFlipY())
                setV(v2 + height /(float)this.height);	
             else 
                setV2(v + height /(float)this.height);
        }
        
        public bool isFlipX() {
            return u > u2;
        }

        public bool isFlipY() {
            return v > v2;
        }
    }
}