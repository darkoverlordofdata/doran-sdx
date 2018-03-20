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
namespace  Sdx.Math {
    /**
     * A Timeline can be used to create complex animations made of sequences and
     * parallel sets of Tweens.
     *
     * The following example will create an animation sequence composed of 5 parts:
     *
     *  1. First, opacity and scale are set to 0 (with Tween.set() calls).
     *  1. Then, opacity and scale are animated in parallel.
     *  1. Then, the animation is paused for 1s.
     *  1. Then, position is animated to x=100.
     *  1. Then, rotation is animated to 360°.
     *
     * This animation will be repeated 5 times, with a 500ms delay between each
     * iteration:
     *
     * {{{
     * Timeline.CreateSequence()
     *     .Push(Tween.Set(myObject, OPACITY).Target({ 0 }))
     *     .Push(Tween.Set(myObject, SCALE).Target({ 0, 0 }))
     *     .BeginParallel()
     *          .Push(Tween.To(myObject, OPACITY, 0.5f).Target({ 1 }).Ease(Interpolation.QuadInOut))
     *          .Push(Tween.To(myObject, SCALE, 0.5f).Target({ 1, 1 }).Ease(Interpolation.QuadInOut))
     *     .End()
     *     .PushPause(1.0f)
     *     .Push(Tween.To(myObject, POSITION_X, 0.5f).Target({ 100 }).Ease(Interpolation.QuadInOut))
     *     .Push(Tween.To(myObject, ROTATION, 0.5f).Target({ 360 }).Ease(Interpolation.QuadInOut))
     *     .Repeat(5, 0.5f)
     *     .Start(myManager);
     * }}}
     *
     * based on code by  Aurelien Ribon 
     * @see Tween
     * @see TweenManager
     * @see Tweenbase.TweenCallback
     */
    public class Timeline : Tweenbase {
        // -------------------------------------------------------------------------
        // Static -- factories
        // -------------------------------------------------------------------------

        /**
         * Creates a new timeline with a 'sequence' behavior. Its children will
         * be delayed so that they are triggered one after the other.
         */
        public static Timeline createSequence() {
            var tl = pool.IsEmpty() ? new Timeline() : (Timeline)pool.Pop().reset();
            tl.setup(TimelineModes.SEQUENCE);
            return tl;
        }
        
        /**
         * Creates a new timeline with a 'parallel' behavior. Its children will be
         * triggered all at once.
         */
        public static Timeline createParallel() {
            var tl = pool.IsEmpty() ? new Timeline() : (Timeline)pool.Pop().reset();
            tl.setup(TimelineModes.PARALLEL);
            return tl;
        }


        // -------------------------------------------------------------------------
        // Setup
        // -------------------------------------------------------------------------

        private Timeline() {
            base();
            _kind = TweenKind.TIMELINE;
            overrides();
            reset();
        }

        protected void setup(TimelineModes mode) {
            _mode = mode;
            _current = this;
        }

        // -------------------------------------------------------------------------
        // Public API
        // -------------------------------------------------------------------------

        /**
         * Adds a Tween to the current timeline.
         * Nests a Timeline in the current one.
         *
         * @return The current timeline, for chaining instructions.
         */
        public Timeline push(Tween tween) {
            if (_isBuilt) throw new Exception.RuntimeException("You can't push anything to a timeline once it is started");
            if (_kind == TweenKind.TIMELINE) {
                if (tween._current != tween) 
                    throw new Exception.RuntimeException("You forgot to call a few 'end()' statements in your pushed timeline");
                tween._parent = _current;
            }
            _current._children.Add(tween);
            return this;
        }

        /**
         * Adds a pause to the timeline. The pause may be negative if you want to
         * overlap the preceding and following _children.
         *
         * @param time A positive or negative duration.
         * @return The current timeline, for chaining instructions.
         */
        public Timeline pushPause(float time) {
            if (_isBuilt) throw new Exception.RuntimeException("You can't push anything to a timeline once it is started");
            _current._children.Add(Tween.mark().delay(time));
            return this;
        }

        /**
         * Starts a nested timeline with a 'sequence' behavior. Don't forget to
         * call {@link End} to close this nested timeline.
         *
         * @return The current timeline, for chaining instructions.
         */
        public Timeline beginSequence() {
            if (_isBuilt) throw new Exception.RuntimeException("You can't push anything to a timeline once it is started");
            var tl = pool.IsEmpty() ? new Timeline() : (Timeline)pool.Pop().reset();
            tl._parent = _current;
            tl._mode = TimelineModes.SEQUENCE;
            _current._children.Add(tl);
            _current = tl;
            return this;
        }

        /**
         * Starts a nested timeline with a 'parallel' behavior. Don't forget to
         * call {@link End} to close this nested timeline.
         *
         * @return The current timeline, for chaining instructions.
         */
        public Timeline beginParallel() {
            if (_isBuilt) throw new Exception.RuntimeException("You can't push anything to a timeline once it is started");
            var tl = pool.IsEmpty() ? new Timeline() : (Timeline)pool.Pop().reset();
            tl._parent = _current;
            tl._mode = TimelineModes.PARALLEL;
            _current._children.Add(tl);
            _current = tl;
            return this;
        }

        /**
         * Closes the last nested timeline.
         *
         * @return The current timeline, for chaining instructions.
         */
        public Timeline end() {
            if (_isBuilt) throw new Exception.RuntimeException("You can't push anything to a timeline once it is started");
            if (_current == this) throw new Exception.RuntimeException("Nothing to end...");
            _current = _current._parent;
            return this;
        }

        /**
         * Gets a list of the timeline _children. If the timeline is started, the
         * list will be immutable.
         */
        public GenericArray<Tweenbase> getChildren() {
            //  if (isBuilt) return Collections.unmodifiableList(current.children);
            //  else return current.children;
            return _current._children;            
        }

        // -------------------------------------------------------------------------
        // Overrides
        // -------------------------------------------------------------------------
        private void overrides() {
            var reset_ = reset;
            var start_ = start;
            reset = () => {
                reset_();
                _children = new GenericArray<Timeline>();
                _current = _parent = null;

                _isBuilt = false;
                return this;
            };
        
            build = () => {
                if (_isBuilt) return this;

                _duration = 0;

                for (int i=0; i<_children.length; i++) {
                    var obj = _children[i];

                    if (obj.getRepeatCount() < 0) throw new Exception.RuntimeException("You can't push an object with infinite repetitions in a timeline");
                    obj.build();

                    switch (_mode) {
                        case TimelineModes.SEQUENCE:
                            float tDelay = _duration;
                            _duration += obj.getFullDuration();
                            obj._delay += tDelay;
                            break;

                        case TimelineModes.PARALLEL:
                            _duration = GLib.Math.fmaxf(_duration, obj.getFullDuration());
                            break;
                    }
                }

                _isBuilt = true;
                return this;

            };

            start = () => {
                start_();

                for (int i=0; i<_children.length; i++) {
                    var obj = _children[i];
                    obj.start();
                }

                return this;
            };

            clear = () => {
                for (int i=_children.length-1; i>=0; i--) {
                    var obj = _children[i];
                    _children.RemoveIndex(i);
                    obj.clear();
                }

                //  pool.clear(this);
            };

            updateOverride = (step, lastStep, isIterationStep, delta) => {
                if (!isIterationStep && step > lastStep) {
                    assert(delta >= 0);
                    float dt = isReverse(lastStep) ? -delta-1 : delta+1;
                    for (int i=0, n=_children.length; i<n; i++) _children[i].update(dt);
                    return;
                }

                if (!isIterationStep && step < lastStep) {
                    assert(delta <= 0);
                    float dt = isReverse(lastStep) ? -delta-1 : delta+1;
                    for (int i=_children.length-1; i>=0; i--) _children[i].update(dt);
                    return;
                }

                assert(isIterationStep);

                if (step > lastStep) {
                    if (isReverse(step)) {
                        forceEndValues();
                        for (int i=0, n=_children.length; i<n; i++) _children[i].update(delta);
                    } else {
                        forceStartValues();
                        for (int i=0, n=_children.length; i<n; i++) _children[i].update(delta);
                    }

                } else if (step < lastStep) {
                    if (isReverse(step)) {
                        forceStartValues();
                        for (int i=_children.length-1; i>=0; i--) _children[i].update(delta);
                    } else {
                        forceEndValues();
                        for (int i=_children.length-1; i>=0; i--) _children[i].update(delta);
                    }

                } else {
                    float dt = isReverse(step) ? -delta : delta;
                    if (delta >= 0) for (int i=0, n=_children.length; i<n; i++) _children[i].update(dt);
                    else for (int i=_children.length-1; i>=0; i--) _children[i].update(dt);
                }

            };

            // -------------------------------------------------------------------------
            // BaseTween impl.
            // -------------------------------------------------------------------------
            forceStartValues = () => {
                for (int i=_children.length-1; i>=0; i--) {
                    var obj = _children[i];
                    obj.forceToStart();
                }
            };

            forceEndValues = () => {
                for (int i=0, n=_children.length; i<n; i++) {
                    var obj = _children[i];
                    obj.forceToEnd(_duration);
                }
            };

            containsTarget = (target, tweenType) => {
                for (int i=0, n=_children.length; i<n; i++) {
                    var obj = _children[i];
                    if (obj.containsTarget(target, tweenType)) return true;
                }
                return false;
            };

        }
    }
}