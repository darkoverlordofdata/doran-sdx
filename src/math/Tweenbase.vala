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
    public enum TimelineModes { SEQUENCE, PARALLEL }
    public enum TweenKind { TWEEN, TIMELINE }
    public delegate void TweenCallbackOnEvent(int type, Tweenbase source);
    /**
     * BaseTween is the base class of Tween and Timeline. It defines the
     * iteration engine used to play animations for any number of times, and in
     * any direction, at any speed.
     * <p/>
     *
     * It is responsible for calling the different callbacks at the right moments,
     * and for making sure that every callbacks are triggered, even if the update
     * engine gets a big delta time at once.
     *
     * based on code by  Aurelien Ribon
     * @see Tween
     * @see Timeline
     */
    public class Tweenbase : Object {
        public enum TweenCallback {
            BEGIN = 0x01,
            START = 0x02,
            END = 0x04,
            COMPLETE = 0x08,
            BACK_BEGIN = 0x10,
            BACK_START = 0x20,
            BACK_END = 0x40,
            BACK_COMPLETE = 0x80,
            ANY_FORWARD = 0x0F,
            ANY_BACKWARD = 0xF0,
            ANY = 0xFF
        }

        protected TweenKind _kind;
	    // General
        private int _step;
        private int _repeatCnt;
        private bool _isIterationStep;
        private bool _isYoyo;

        // Timings
        protected float _delay;
        protected float _duration;
        private float _repeatDelay;
        private float _currentTime;
        private float _deltaTime;
        private bool _isStarted;  // true when the object is started
        private bool _isInitialized; // true after the delay
        private bool _isFinished; // true when all repetitions are done
        private bool _isKilled;   // true when kill was called
        private bool _isPaused;   // true when pause was called

	    // Misc
        private TweenCallbackOnEvent _callback;
        private int _callbackTriggers;
        private void* _userData;

	    // Package access
        public bool isAutoRemoveEnabled;
        public bool isAutoStartEnabled;
        
        // -------------------------------------------------------------------------
        // Static -- misc
        // -------------------------------------------------------------------------

        /**
         * Used as parameter in {@link Repeat} and
         * {@link RepeatYoyo} methods.
         */
        protected static int combinedAttrsLimit = 3;
        protected static int waypointsLimit = 0;

        // -------------------------------------------------------------------------
        // Static -- pool
        // -------------------------------------------------------------------------
        public static Stack<Tweenbase> pool;

        // -------------------------------------------------------------------------
        // Static -- tween accessors
        // -------------------------------------------------------------------------
        //  public static HashTable<string,TweenAccessor> registeredAccessors;
        public static HashTable<void*,TweenAccessor> registeredAccessors;

        // -------------------------------------------------------------------------
        // Attributes (Tween)
        // -------------------------------------------------------------------------

        // Main
        protected void* _target;
        protected Class* _targetClass;
        protected TweenAccessor _accessor;
        protected int _type;
        protected Interpolation _equation;

    	// General
        protected bool _isFrom;
        protected bool _isRelative;
        protected int _combinedAttrsCnt;
        protected int _waypointsCnt;
    
        // Values
        protected float[] _startValues = new float[combinedAttrsLimit];
        protected float[] _targetValues = new float[combinedAttrsLimit];

    	// Buffers
	    protected float[] _accessorBuffer = new float[combinedAttrsLimit];

        
        // -------------------------------------------------------------------------
        // Attributes (Timeline)
        // -------------------------------------------------------------------------
        //  public enum Modes {SEQUENCE, PARALLEL}

        protected GenericArray<Tweenbase> _children;
        protected Tweenbase _current;
        protected Tweenbase _parent;
        protected TimelineModes _mode;
        protected bool _isBuilt;

        public delegate Tweenbase TweenReset();

        // -------------------------------------------------------------------------
        // Public API
        // -------------------------------------------------------------------------

        /**
         * Builds and validates the object. Only needed if you want to finalize a
         * tween or timeline without starting it, since a call to ".start()" also
         * calls this method.
         *
         * @return The current object, for chaining instructions.
         */
        public delegate Tweenbase TweenBuild();
        /**
         * Stops and resets the tween or timeline, and sends it to its pool, for
         * later reuse. Note that if you use a {@link TweenManager}, this method
         * is automatically called once the animation is finished.
         */
        public delegate void TweenClear();
        public delegate Tweenbase TweenStart(TweenManager? manager = null);

        
        /* Virtual methods */
        protected TweenReset reset = () => {};
        public TweenBuild build = () => {};
        public TweenClear clear = () => {};
        public TweenStart start = (manager) => {};

        public Tweenbase() {
            reset = () => {
                _step = -2;
                _repeatCnt = 0;
                _isIterationStep = _isYoyo = false;

                _delay = _duration = _repeatDelay = _currentTime = _deltaTime = 0;
                _isStarted = _isInitialized = _isFinished = _isKilled = _isPaused = false;

                _callback = null;
                _callbackTriggers = TweenCallback.COMPLETE;
                _userData = null;

                isAutoRemoveEnabled = isAutoStartEnabled = true;
                return this;
            };

            start = (manager) => {
                if (manager == null) {
                    /**
                     * Starts or restarts the object unmanaged. You will need to take care of
                     * its life-cycle. If you want the tween to be managed for you, use a
                     * {@link TweenManager}.
                     *
                     * @return The current object, for chaining instructions.
                     */
                    build();
                    _currentTime = 0;
                    _isStarted = true;
                } else {
                    /**
                     * Convenience method to add an object to a manager. Its life-cycle will be
                     * handled for you. Relax and enjoy the animation.
                     *
                     * @return The current object, for chaining instructions.
                     */
                    manager.add(this);
                }
                return this;
            };
        }

        //  public Tweenbase Start(TweenManager? manager = null)
        //  {
        //      if (manager == null)
        //      {
        //          /**
        //           * Starts or restarts the object unmanaged. You will need to take care of
        //           * its life-cycle. If you want the tween to be managed for you, use a
        //           * {@link TweenManager}.
        //           *
        //           * @return The current object, for chaining instructions.
        //           */
        //          Build();
        //          currentTime = 0;
        //          isStarted = true;
        //      }
        //      else
        //      {
        //          /**
        //           * Convenience method to add an object to a manager. Its life-cycle will be
        //           * handled for you. Relax and enjoy the animation.
        //           *
        //           * @return The current object, for chaining instructions.
        //           */
        //          manager.Add(this);
        //      }
        //      return this;
        //  }
        /**
         * Adds a delay to the tween or timeline.
         *
         * @param delay A duration.
         * @return The current object, for chaining instructions.
         */
        public Tweenbase delay(float delay) {
            _delay += delay;
            return this;
        }

        /**
         * Kills the tween or timeline. If you are using a TweenManager, this object
         * will be removed automatically.
         */
        public void kill() {
            _isKilled = true;
        }
        /**
         * Pauses the tween or timeline. Further update calls won't have any effect.
         */
        public void pause() {
            _isPaused = true;
        }

        /**
         * Resumes the tween or timeline. Has no effect is it was no already paused.
         */
        public void resume() {
            _isPaused = false;
        }

        /**
         * Repeats the tween or timeline for a given number of times.
         * @param count The number of repetitions. For infinite repetition,
         * use Tween.INFINITY, or a negative number.
         *
         * @param delay A delay between each iteration.
         * @return The current tween or timeline, for chaining instructions.
         */
        public Tweenbase repeat(int count, float delay=0) {
            if (_isStarted) 
                throw new Exception.RuntimeException("You can't change the repetitions of a tween or timeline once it is started");
            _repeatCnt = count;
            _repeatDelay = delay >= 0 ? delay : 0;
            _isYoyo = false;
            return this;            
        }

        /**
         * Repeats the tween or timeline for a given number of times.
         * Every two iterations, it will be played backwards.
         *
         * @param count The number of repetitions. For infinite repetition,
         * use Tween.INFINITY, or '-1'.
         * @param delay A delay before each repetition.
         * @return The current tween or timeline, for chaining instructions.
         */
        public Tweenbase repeatYoyo(int count, float delay=0) {
            if (_isStarted) 
                throw new Exception.RuntimeException("You can't change the repetitions of a tween or timeline once it is started");
            _repeatCnt = count;
            _repeatDelay = delay >= 0 ? delay : 0;
            _isYoyo = true;
            return this;            
        }

        /**
         * Sets the callback. By default, it will be fired at the completion of the
         * tween or timeline (event COMPLETE). If you want to change this behavior
         * and add more triggers, use the {@link SetCallbackTriggers} method.
         *
         * @see TweenCallback
         */
        public Tweenbase setCallback(TweenCallbackOnEvent callback) {
            _callback = callback;
            return this;
        }
        
        /**
         * Changes the triggers of the callback. The available triggers, listed as
         * members of the {@link TweenCallback} interface, are:
         *
         *  * ''BEGIN'': right after the delay (if any)
         *  * ''START'': at each iteration beginning
         *  * ''END'': at each iteration ending, before the repeat delay
         *  * ''COMPLETE'': at last END event
         *  * ''BACK_BEGIN'': at the beginning of the first backward iteration
         *  * ''BACK_START'': at each backward iteration beginning, after the repeat delay
         *  * ''BACK_END'': at each backward iteration ending
         *  * ''BACK_COMPLETE'': at last BACK_END event
         *
         * {{{
         * forward :      BEGIN                                   COMPLETE
         * forward :      START    END      START    END      START    END
         * |--------------[XXXXXXXXXX]------[XXXXXXXXXX]------[XXXXXXXXXX]
         * backward:      bEND  bSTART      bEND  bSTART      bEND  bSTART
         * backward:      bCOMPLETE                                 bBEGIN
         * }}}
         *
         * @param flags one or more triggers, separated by the '|' operator.
         * @see TweenCallback
         */
        public Tweenbase setCallbackTriggers(int flags) {
            _callbackTriggers = flags;
            return this;
        }

        /**
         * Attaches an object to this tween or timeline. It can be useful in order
         * to retrieve some data from a TweenCallback.
         *
         * @param data Any kind of object.
         * @return The current tween or timeline, for chaining instructions.
         */
        public Tweenbase setUserData(void* data) {
            _userData = data;
            return this;
        }

        // -------------------------------------------------------------------------
        // Getters
        // -------------------------------------------------------------------------

        /**
         * Gets the delay of the tween or timeline. Nothing will happen before
         * this delay.
         */
        public float getDelay() {
            return _delay;
        }

        /**
         * Gets the duration of a single iteration.
         */
        public float getDuration() {
            return _duration;
        }

        /**
         * Gets the number of iterations that will be played.
         */
        public int getRepeatCount() {
            return _repeatCnt;
        }
        
        /**
         * Gets the delay occuring between two iterations.
         */
        public float getRepeatDelay() {
    		return _repeatDelay;
        }
        
        /**
         * Returns the complete duration, including initial delay and repetitions.
         * The formula is as follows:
         * {{{
         * fullDuration = delay + duration + (repeatDelay + duration) * repeatCnt
         * }}}
         */
        public float getFullDuration() {
            if (_repeatCnt < 0) return -1;
            return _delay + _duration + (_repeatDelay + _duration) * _repeatCnt;
        }

        /**
         * Gets the attached data, or null if none.
         */
        public void* getUserData() {
            return _userData;
        }

        /**
         * Gets the id of the current step. Values are as follows:
         * 
         *  * even numbers mean that an iteration is playing,
         *  * odd numbers mean that we are between two iterations,
         *  * -2 means that the initial delay has not ended,
         *  * -1 means that we are before the first iteration,
         *  * repeatCount*2 + 1 means that we are after the last iteration
         */
        public int getStep() {
            return _step;
        }

        /**
         * Gets the local time.
         */
        public float getCurrentTime() {
            return _currentTime;
        }
        
        /**
         * Returns true if the tween or timeline has been started.
         */
        public bool isStarted() {
            return _isStarted;
        }
        
        /**
         * Returns true if the tween or timeline has been initialized. Starting
         * values for tweens are stored at initialization time. This initialization
         * takes place right after the initial delay, if any.
         */
        public bool isInitialized() {
            return _isInitialized;
        }
        
        /**
         * Returns true if the tween is finished (i.e. if the tween has reached
         * its end or has been killed). If you don't use a TweenManager, you may
         * want to call {@link Clear} to reuse the object later.
         */
        public bool isFinished() {
            return _isFinished || _isKilled;
        }

        /**
         * Returns true if the iterations are played as yoyo. Yoyo means that
         * every two iterations, the animation will be played backwards.
         */
        public bool isYoyo() {
            return _isYoyo;
        }

        /**
         * Returns true if the tween or timeline is currently paused.
         */
        public bool isPaused() {
            return _isPaused;
        }

        // -------------------------------------------------------------------------
        // Abstract API
        // -------------------------------------------------------------------------
        public delegate void TweenForceStartValues();
        public delegate void TweenForceEndValues();
        public delegate bool TweenContainsTarget(void* target, int tweenType=-1);
       
        protected TweenForceStartValues forceStartValues = () => {};
        protected TweenForceEndValues forceEndValues = () => {};
        public TweenContainsTarget containsTarget = (target, tweenType) => {};

        // -------------------------------------------------------------------------
        // Protected API
        // -------------------------------------------------------------------------
        public delegate void TweenInitializeOverride();
        public delegate void TweenUpdateOverride(int step, int lastStep, bool isIterationStep, float delta);

        protected TweenInitializeOverride initializeOverride = () => {}; 
        protected TweenUpdateOverride updateOverride = (step, lastStep, isIterationStep, delta) => {}; 

        protected void forceToStart() {
            _currentTime = -_delay;
            _step = -1;
            _isIterationStep = false;
            if (isReverse(0)) forceEndValues();
            else forceStartValues();
        }

        protected void forceToEnd(float time) {
            _currentTime = time - getFullDuration();
            _step = _repeatCnt*2 + 1;
            _isIterationStep = false;
            if (isReverse(_repeatCnt*2)) forceStartValues();
            else forceEndValues();
        }
        
        protected void callCallback(int type) {
            //  print("CallCallback %d\n", type);
            if (_callback != null && (_callbackTriggers & type) > 0) _callback(type, this);
        }
        

        protected bool isReverse(int step) {
            return _isYoyo && GLib.Math.fabs(step%4) == 2;
        }

        protected bool isValid(int step) {
            return (_step >= 0 && _step <= _repeatCnt*2) || _repeatCnt < 0;
        }

        public void killTarget(void* target, int tweenType=-1) {
            if (containsTarget(target, tweenType)) kill();
        }

        // -------------------------------------------------------------------------
        // Update engine
        // -------------------------------------------------------------------------

        /**
         * Updates the tween or timeline state. 
         * ''You may want to use a TweenManager to update objects for you.''
         *
         * Slow motion, fast motion and backward play can be easily achieved by
         * tweaking this delta time. Multiply it by -1 to play the animation
         * backward, or by 0.5 to play it twice slower than its normal speed.
         *
         * @param delta A delta time between now and the last call.
         */
        public void update(float delta) {
            //  print(" isStarted %s\n", isStarted.ToString());
            //  print(" isPaused %s\n", isPaused.ToString());
            //  print(" isKilled %s\n", isKilled.ToString());
            if (!_isStarted || _isPaused || _isKilled) return;

            _deltaTime = delta;

            if (!_isInitialized) {
                initialize();
            }

            if (_isInitialized) {
                testRelaunch();
                updateStep();
                testCompletion();
            }

            _currentTime += _deltaTime;
            _deltaTime = 0;

        }

        private void initialize() {
            if (_currentTime+_deltaTime >= _delay) {
                initializeOverride();
                _isInitialized = true;
                _isIterationStep = true;
                _step = 0;
                _deltaTime -= _delay-_currentTime;
                _currentTime = 0;
                callCallback(TweenCallback.BEGIN);
                callCallback(TweenCallback.START);
            }
        }
        
        private void testRelaunch() {
            if (!_isIterationStep && _repeatCnt >= 0 && _step < 0 && _currentTime+_deltaTime >= 0) {
                assert(_step == -1);
                _isIterationStep = true;
                _step = 0;
                float delta = 0-_currentTime;
                _deltaTime -= delta;
                _currentTime = 0;
                callCallback(TweenCallback.BEGIN);
                callCallback(TweenCallback.START);
                updateOverride(_step, _step-1, _isIterationStep, delta);

            } else if (!_isIterationStep && _repeatCnt >= 0 && _step > _repeatCnt*2 && _currentTime+_deltaTime < 0) {
                assert(_step == _repeatCnt*2 + 1);
                _isIterationStep = true;
                _step = _repeatCnt*2;
                float delta = 0-_currentTime;
                _deltaTime -= delta;
                _currentTime = _duration;
                callCallback(TweenCallback.BACK_BEGIN);
                callCallback(TweenCallback.BACK_START);
                updateOverride(_step, _step+1, _isIterationStep, delta);
            }
        }

        private void updateStep() {
            while (isValid(_step)) {
                if (!_isIterationStep && _currentTime+_deltaTime <= 0) {
                    _isIterationStep = true;
                    _step -= 1;

                    float delta = 0-_currentTime;
                    _deltaTime -= delta;
                    _currentTime = _duration;

                    if (isReverse(_step)) forceStartValues(); else forceEndValues();
                    callCallback(TweenCallback.BACK_START);
                    updateOverride(_step, _step+1, _isIterationStep, delta);

                } else if (!_isIterationStep && _currentTime+_deltaTime >= _repeatDelay) {
                    _isIterationStep = true;
                    _step += 1;

                    float delta = _repeatDelay-_currentTime;
                    _deltaTime -= delta;
                    _currentTime = 0;

                    if (isReverse(_step)) forceEndValues(); else forceStartValues();
                    callCallback(TweenCallback.START);
                    updateOverride(_step, _step-1, _isIterationStep, delta);

                } else if (_isIterationStep && _currentTime+_deltaTime < 0) {
                    _isIterationStep = false;
                    _step -= 1;

                    float delta = 0-_currentTime;
                    _deltaTime -= delta;
                    _currentTime = 0;

                    updateOverride(_step, _step+1, _isIterationStep, delta);
                    callCallback(TweenCallback.BACK_END);

                    if (_step < 0 && _repeatCnt >= 0) callCallback(TweenCallback.BACK_COMPLETE);
                    else _currentTime = _repeatDelay;

                } else if (_isIterationStep && _currentTime+_deltaTime > _duration) {
                    _isIterationStep = false;
                    _step += 1;

                    float delta = _duration-_currentTime;
                    _deltaTime -= delta;
                    _currentTime = _duration;

                    updateOverride(_step, _step-1, _isIterationStep, delta);
                    callCallback(TweenCallback.END);

                    if (_step > _repeatCnt*2 && _repeatCnt >= 0) callCallback(TweenCallback.COMPLETE);
                    _currentTime = 0;

                } 
                else if (_isIterationStep) {
                    float delta = _deltaTime;
                    _deltaTime -= delta;
                    _currentTime += delta;
                    updateOverride(_step, _step, _isIterationStep, delta);
                    break;

                } else {
                    float delta = _deltaTime;
                    _deltaTime -= delta;
                    _currentTime += delta;
                    break;
                }
            }
        }
            
        private void testCompletion() {
            _isFinished = _repeatCnt >= 0 && (_step > _repeatCnt*2 || _step < 0);
        }

    }
}