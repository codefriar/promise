/*
 * PromiseBase.cls
 * Author: Kevin Poorman, with heavy influence from Chuck Jonas
 * Email: kjp@codefriar.com
 * Github: https://github.com/codefriar/promise
 * This is Promise, a library for asynchronous Apex execution using the promise pattern and Queueable Apex.
 * This code was derived from Chuck Jonas' work here: https://github.com/ChuckJonas/APEX-Q
 * Which in turn was distilled from a Dreamforce '16 presentation I did.
 */

// This class implements two standard interfaces from the SF Platform:
// * Queueable - which allows for async queuing and processing
// * Database.AllowsCallouts - which allows for making http callouts
Public Class Promise Extends PromiseBase Implements Queueable, Database.AllowsCallouts {

  // This list holds the steps of your promise chain.
  Protected List<SerializableData> steps = new List<SerializableData>();

  // Constructors
  Public Promise() {
  }
  Public Promise(PromiseStep promiseStep) {
    then(promiseStep);
  }

  /**
   * Add a new promise promiseStep to the execution stack
   * @param         promiseStep PromiseStep to execute
   * @return        this (enables chaining)
   */
  Public PromiseBase then(Promise.PromiseStep promiseStep) {
    steps.add(new SerializableData(promiseStep));
    return this;
  }

  /**
   * Begin the execution of the steps contained in the steps list.
   * @param           QueableContext qc - injected by the system
   * @return          void
   */
  Public Void execute(QueueableContext qc) {
    Promise.PromiseStep currentPromiseStep; // will hold the deserialized object representing the current step
    SerializableData resolution; // will hold the output of this steps resolve function
    try {
      // pop the first step item off the list then deserialize it into the currentPromiseStep variable
      SerializableData sd = (SerializableData) steps.remove(0);
      currentPromiseStep = (Promise.PromiseStep) JSON.deserialize(sd.objJson, Type.forName(sd.classType));
      // execute the current step's resolve function
      resolution = (SerializableData) currentPromiseStep.resolve(dataPassthrough);

      // Having executed the current step, lets see if there any other steps to invoke?
      if (steps.size() > 0) {
        // if there are other steps, enqueue the next step.
        Promise.enqueueJobInFture(
          getInstanceClassName(this),
          JSON.Serialize(steps),
          resolution.objJson,
          resolution.classType,
          (errorHandler == null) ? null : JSON.serialize(errorHandler),
          getInstanceClassName(errorHandler),
          (doneHandler == null) ? null : JSON.serialize(doneHandler),
          getInstanceClassName(doneHandler)
        );
        return;
      }
      // If we've failed at executing the current step, or in enquing the next step, catch the exception here.
    } catch (Exception pe) {
      // if the error handler class has been specified then we'll invoke the errorHandler's error method with the
      // exception.
      if (errorHandler != null) {
        resolution = (SerializableData) errorHandler.error(pe);
      } else {
        // otherwise, if we don't have an errorHandler defined, simply log the error, and the stack trace then
        // pass the exception up.
        system.debug('An exception has occured during the processing of this Promise Stack. However no Error Handler was defined.\nThe error message is: ' + pe.getMessage() + '\nAnd the stackTrace is: \n' + pe.getStackTraceString());
        throw pe;
      }
    }
    // If there are no more steps, and if the done handler was specified, invoke it with the results of the
    // last step.
    if (doneHandler != null) {
      doneHandler.done(JSON.deserialize(resolution.objJson, Type.forName(resolution.classType)));
    }
  }

  /**
   * Queuable apex is almost perfect. While Queueable Apex can enqueue other Queueable Apex
   * classes, when you chain two Queueable Apex classes that each make an HTTP Callout you'll
   * get the dreaded 'you have uncommitted work pending...' error. Queueable Apex doesn't seem
   * to reset the DML context upon execution of additional Queueable Apex classes.
   *
   * To 'fix' this, and allow any given promiseStep to make an http callout, this lib
   * enqueues the individual steps from an @future context. This effectively resets the DML
   * context and allows each step to make a callout while still being chained together.
   */
  @future(Callout=true)
  Public Static Void enqueueJobInFture(String promiseClassName,
    String promiseStack,
    String dataPassthrough,
    String dataPassThroughType,
    String error,
    String errorClassName,
    String done,
    String doneClassName) {
    // Each of the inputs is a string, which is why the individual steps must all be serializable as JSON!
    // Create an empty promise
    Promise p = new Promise();
    // Having popped the current step off the step list earlier, we now set the new promise's steps to
    // the remaining steps that were serialized and passed in.
    p.steps = (List<SerializableData>) JSON.deserialize(promiseStack, SerializableData[].class);

    // if we have an error handler, set it.
    if (error != null && errorClassName != null) {
      p.error((Promise.Error) JSON.deserialize(error, Type.forName(errorClassName)));
    }

    // if we have a done handler, set it.
    if (done != null && doneClassName != null) {
      p.done((Promise.Done) JSON.deserialize(done, Type.forName(doneClassName)));
    }

    // if we have data from the last steps' resolution set it here.
    if (dataPassthrough != null && dataPassThroughType != null) {
      Type dptType = Type.forName(dataPassThroughType);
      if (dptType != null) {
        p.dataPassThrough = JSON.deserialize(dataPassThrough, dptType);
      } else { // use generic JSON deserialization
        p.dataPassThrough = JSON.deserializeUntyped(dataPassthrough);
      }
    }
    // finally, enqueue the new promise for execution.
    System.enqueueJob(p);
  }

  /**
   * Standard interfaces
   * These interfaces define PromiseStep, Error and Done classes required methods.
   */
  Public Interface PromiseStep {
    Object resolve(Object input);
  }

  Public Interface Error {
    Object error(Exception e);
  }

  Public Interface Done {
    void done(Object input);
  }

  /**
   * Because of the @future context, only primitives like Strings can be passed in
   * As such, we have this serializable data class, that can be serialized to json
   * and passed arround.
   *
   * All your PromiseStep classes should return a SerializedData object!
   */
  Public class SerializableData {
    Public String classType { get; Private set; }
    Public String objJson { get; Private set; }
    Public SerializableData(Promise.PromiseStep promiseStep) {
      classType = getInstanceClassName(promiseStep);
      objJson = JSON.serialize(promiseStep);
    }
    Public SerializableData(Object obj, Type t) {
      this.objJson = JSON.serialize(obj);
      this.classType = t.getName();
    }
  }

  // Helper Methods

  // Quick (and dirty) method to extract the string representation of the class name
  // from the JSON serialized string.
  @TestVisible
  Private Static String getInstanceClassName(Object input) {
    if (input != null) {
      return String.valueOf(input).split(':')[0];
    }
    return null;
  }
}