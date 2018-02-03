Public Virtual Class Promise Implements Queueable, Database.AllowsCallouts {

    //   ___           _                     __     __
    //  |_ _|_ __  ___| |_ __ _ _ __   ___ ___ \   / /_ _ _ __ ___
    //   | || '_ \/ __| __/ _` | '_ \ / __/ _ \ \ / / _` | '__/ __|
    //   | || | | \__ \ |_ (_| | | | | (__  __/\ V / (_| | |  \__ \
    //  |___|_| |_|___/\__\__,_|_| |_|\___\___| \_/ \__,_|_|  |___/
    //

    /**
     * promiseStack is the fundamental data structure used to chain Promise.Deferred
     * instances. Because lists are ordered, we can ensure the order of execution
     * of the various steps in this promise chain.
     */
    Protected List<Promise.Deferred> promiseStack = new List<Promise.Deferred>();

    /**
     * If this is true, the next Deferred in the promiseStack will NOT be run after
     * a resolve() method is completed.  This allows for other processes (like batch jobs)
     * to be inserted, and control the pause/resume flow.
     */
    Protected Boolean isPaused = false;

    /**
     * promiseData stores the results of the immediately previous execution step
     *    the .execute(QueueableContext qc) method passes the current value of
     *    this variable into the *next* Promise.Deferred implementing classes
     *    resolve method.
     *
     *  N.B. The original call to .execute(Object o) sets the value of this
     *    this variable to o.
     */
    Protected Object promiseData;

    /**
     * state is the single place that all Deferreds can use to publish
     * data for use by subsequent steps.  This could be accomplished by
     * passing things through input, but this simplifies it by providing
     * consistent access.
     */
    Public Map<String, Object> state = new Map<String, Object>();

    /**
     * These two variables hold references to this promise chain's
     *    error and done handlers. These handlers are executed in
     *    the event of an error, or when the chain completes all
     *    the promiseStacks instances' .resolve() methods
     */
    Protected Promise.Error errorHandler;
    Protected Promise.Done doneHandler;

    //    ____                _                   _
    //   / ___|___  _ __  ___| |_ _ __ _   _  ___| |_ ___  _ __ ___
    //  | |   / _ \| '_ \/ __| __| '__| | | |/ __| __/ _ \| '__/ __|
    //  | |___ (_) | | | \__ \ |_| |  | |_| | (__| |_ (_) | |  \__ \
    //   \____\___/|_| |_|___/\__|_|   \__,_|\___|\__\___/|_|  |___/
    //

    /**
     * Constructor.
     * returns Promise instance
     */
    Public Promise() {
    }

    /**
     * Constructor.
     * @param Promise.Deferred deferred - Instance of class that implements Promise.Deferred
     * returns Promise instance
     */
    Public Promise(Promise.Deferred deferred) {
        then(deferred);
    }

    //   __  __      _   _               _
    //  |  \/  | ___| |_| |__   ___   __| |___
    //  | |\/| |/ _ \ __| '_ \ / _ \ / _` / __|
    //  | |  | |  __/ |_| | | | (_) | (_| \__ \
    //  |_|  |_|\___|\__|_| |_|\___/ \__,_|___/
    //

    /**
     * Add a new Promise.Deferred class instance to the promise stack
     * @param   Promise.Deferred deferred class to execute asynchronusly (But in order)
     * @return  this (for chaining)
     */
    Public Promise then(Promise.Deferred deferred) {
        deferred.setPromise(this);
        promiseStack.add(deferred);
        return this;
    }

    /**
     * Add a new Promise.Deferred class instance to the beginning of the promise stack
     * @param   Promise.Deferred deferred class to execute asynchronously (But in order)
     * @return  this (for chaining)
     */
    Public Promise first(Promise.Deferred deferred) {
        deferred.setPromise(this);
        promiseStack.add(0, deferred);
        return this;
    }

    /**
     * Sets the error (Catch) handler.
     * While you can only set one error handler, that error handler
     *    can be written to parse different types etc.
     * @param  errorHandler The handler to use
     * @return              this (for chaining)
     */
    Public Promise error(Promise.Error errorHandler) {
        errorHandler.setPromise(this);
        this.errorHandler = errorHandler;
        return this;
    }

    /**
     * Sets the Done (Finally) handler.
     * While you can set only one done handler, you should be aware
     *    that the done handler *always* runs. *always*
     * @param  doneHandler The handler to use
     * @return             this (for chaining)
     */
    Public Promise done(Promise.Done doneHandler) {
        doneHandler.setPromise(this);
        this.doneHandler = doneHandler;
        return this;
    }

    /**
     * Puts a value into the state.
     *
     * @param name the String key.
     * @param value the Object value.
     *
     * @return this (for chaining)
     */
    Public Promise set(String name, Object value) {
        return put(name, value);
    }

    /**
     * Puts a value into the state.
     *
     * @param name the String key.
     * @param value the Object value.
     *
     * @return this (for chaining)
     */
    Public Promise put(String name, Object value) {
        this.state.put(name, value);
        return this;
    }

    /**
     * Returns a value from the state.
     *
     * @param name the String key.
     *
     * @return the stored value, or null if not available.
     */
    Public Object get(String name) {
        return this.state.get(name);
    }

    /**
     * Tells whether the state contains a key of the given name.
     *
     * @param name the String key.
     *
     * @return True if the key exists in state; false otherwise.
     */
    Public Boolean containsKey(String name) {
        return this.state.containsKey(name);
    }


    //   ____                      _          _____                     _   _
    //  |  _ \ _ __ ___  _ __ ___ (_)___  ___| ____|_  _____  ___ _   _| |_(_) ___  _ __
    //  | |_) | '__/ _ \| '_ ` _ \| / __|/ _ \  _| \ \/ / _ \/ __| | | | __| |/ _ \| '_ \
    //  |  __/| | | (_) | | | | | | \__ \  __/ |___ >  <  __/ (__| |_| | |_| | (_) | | | |
    //  |_|   |_|  \___/|_| |_| |_|_|___/\___|_____/_/\_\___|\___|\__,_|\__|_|\___/|_| |_|
    //

    /**
     * This version of execute kicks off a promise chain.
     * @param input Object to pass to the first Promise.deferred
     *    implementing class in the promiseStack
     */
    Public Promise execute(Object input) {
        if(input instanceof QueueableContext) {
            QueueableExecute((QueueableContext) input);
            return null;
        } else {
            promiseData = input;
            System.enqueueJob(this);
            return this;
        }
    }

    /**
     * This version of execute kicks off a promise chain
     *    but crucially does not pass any initial data
     *    to the first promise.deferred object.
     */
    Public Promise execute() {
        System.enqueueJob(this);
        return this;
    }

    /**
     * Iterates through the promiseStack instance variable,
     *    executing each promiseBase.Deferred instance in a Queueable context
     * @param context System Injected
     * @return Void will either return nothing (void) or enqueue the next
     *    Next item in the promiseStack
     */
    Public Void Execute(QueueableContext context) {
        QueueableExecute(context);
    }
    Public Void QueueableExecute(QueueableContext context) {
        try {
            Promise.Deferred currentPromise = promiseStack.remove(0);
            promiseData = currentPromise.resolve(promiseData);
            if (isPaused) return;
            if (promiseStack.size() > 0) {
                System.enqueueJob(this);
                return;
            }
        } catch (Exception e) {
            promiseData = errorHandler.error(e);
        }
        doneHandler.done(promiseData);
    }

    /**
     * Pauses execution until the resume() method is called.  This allows
     * for interrupted flow, like in Batch or Scheduled jobs.
     */
    Public Void pause() {
        this.isPaused = true;
    }

    /**
     * Resumes paused execution.
     */
    Public Void resume() {
        this.isPaused = false;
        if(promiseStack.size() > 0){
            System.enqueueJob(this);
            return;
        }
        doneHandler.done(promiseData);
    }

    //    ____                  ____ _
    //   | __ )  __ _ ___  ___ / ___| | __ _ ___ ___  ___  ___
    //   |  _ \ / _` / __|/ _ \ |   | |/ _` / __/ __|/ _ \/ __|
    //   | |_) | (_| \__ \  __/ |___| | (_| \__ \__ \  __/\__ \
    //   |____/ \__,_|___/\___|\____|_|\__,_|___/___/\___||___/
    //

    /**
     * The Deferred interface specifies only the resolve method
     *    This resolve method must accept and return an Object.
     *    The Promise.execute() method injects the output of the
     *    previous step into the current step's resolve method.
     *
     * This allows you to pass data from one Promise.Deferred
     *    implementing class to the next.
     *
     */
    Public Abstract Class Deferred Extends Step {
        Abstract Object resolve(Object input);
    }

    /**
     * The Step class provides the setPromise method, which is called
     * in then(), error(), and done().  It provides the Promise context
     * to the instance, so that it may view and manipulate the state
     * and the call stack.
     */
    Public Virtual Class Step {
        Protected Promise p;
        /**
         * @param p The Promise to cache
         */
        Public Void setPromise(Promise p) {
            this.p = p;
        }
    }

    /**
     * The Error interface specifies only the error(Exception e)
     *    method. It's clunky, but the error method must also
     *    return an object so that the Done handler can be
     *    executed after an error occurs.
     */
    Public Abstract Class Error Extends Step {
        Abstract Object error(Exception e);
    }

    /**
     * The Done interface requires only the done(Object) method
     * to be specified by the end-developer. This method is run
     * regardless of error status if it's included in the promise
     * chain.
     */
    Public Abstract Class Done Extends Step {
        Abstract Void done(Object input);
    }

}