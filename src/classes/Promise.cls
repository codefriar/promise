Public Virtual Class Promise Implements Queueable, Database.AllowsCallouts {
  //   ___           _                     __     __
  //  |_ _|_ __  ___| |_ __ _ _ __   ___ ___ \   / /_ _ _ __ ___
  //   | || '_ \/ __| __/ _` | '_ \ / __/ _ \ \ / / _` | '__/ __|
  //   | || | | \__ \ |_ (_| | | | | (__  __/\ V / (_| | |  \__ \
  //  |___|_| |_|___/\__\__,_|_| |_|\___\___| \_/ \__,_|_|  |___/
  //

  /*
   * promiseStack is the fundamental data structure used to chain Promise.derer
   * instances. Because lists are ordered, we can ensure the order of execution
   * of the various steps in this promise chain.
   */
  Protected List<Promise.Deferred> promiseStack = new List<Promise.Deferred>();

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

  /*
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
    promiseStack.add(deferred);
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
    this.doneHandler = doneHandler;
    return this;
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
  Public Void execute(Object input) {
    promiseData = input;
    System.enqueueJob(this);
  }

  /**
   * This version of execute kicks off a promise chain
   *    but crucially does not pass any initial data
   *    to the first promise.deferred object.
   */
  Public Void execute() {
    System.enqueueJob(this);
  }

  /**
   * Iterates through the promiseStack instance variable,
   *    executing each promiseBase.Deferred instance in a Queueable context
   * @param context System Injected
   * @return Void will either return nothing (void) or enqueue the next
   *    Next item in the promiseStack
   */
  Public Void execute(QueueableContext context) {
    try {
      Promise.Deferred currentPromise = promiseStack.remove(0);
      promiseData = currentPromise.resolve(promiseData);
      if (promiseStack.size() > 0) {
        System.enqueueJob(this);
        return;
      }
    } catch (Exception e) {
      promiseData = errorHandler.error(e);
    }
    doneHandler.done(promiseData);
  }

  //   ___       _             __
  //  |_ _|_ __ | |_ ___ _ __ / _| __ _  ___ ___ ___
  //   | || '_ \| __/ _ \ '__| |_ / _` |/ __/ _ \ __|
  //   | || | | | |_  __/ |  |  _| (_| | (__  __\__ \
  //  |___|_| |_|\__\___|_|  |_|  \__,_|\___\___|___/
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
  Public Interface Deferred {
    Object resolve(Object input);
  }

  /**
   * The Error interface specifies only the error(Exception e)
   *    method. It's clunky, but the error method must also
   *    return an object so that the Done handler can be
   *    executed after an error occurs.
   */
  Public Interface Error {
    Object error(Exception e);
  }

  /**
   * The Done interface requires only the done(Object) method
   * to be specified by the end-developer. This method is run
   * regardless of error status if it's included in the promise
   * chain.
   */
  Public Interface Done {
    Void done(Object input);
  }

}