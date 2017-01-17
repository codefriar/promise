/*
 * PromiseBase.cls
 * Author: Kevin Poorman, with heavy influence from Chuck Jonas
 * Email: kjp@codefriar.com
 * Github: https://github.com/codefriar/promise
 * This is Promise, a library for asynchronous Apex execution using the promise pattern and Queueable Apex.
 * This code was derived from Chuck Jonas' work here: https://github.com/ChuckJonas/APEX-Q
 * Which in turn was distilled from a Dreamforce '16 presentation I did.
 */

Public Abstract Class PromiseBase {

  // instance variables for standard error and done handlers.
  Protected Promise.error errorHandler;
  Protected Promise.done doneHandler;

  // Data conduit between promises. The output of each step's resolve method
  // is stored here for the next step to have access to. Note, the framework
  // automatically dependency injects this data when it invokes the next steps
  // resolve method
  Public Object dataPassthrough;

  // Handler setters

  /**
   * sets the error handler. Only one error handler can be active at once.
   * @param   errorHandler The object to use as the Error Handler. Must implement Promise.Error
   * @return  this         Must return this to enable chaining to other handlers (ie. done)
   */
  Public PromiseBase error(Promise.Error errorHandler) {
    this.errorHandler = errorHandler;
    return this;
  }

  /**
   * sets the done handler. Only one done handler can be active at once.PromiseBase
   * @param   doneHandler the object to use as the done handler. Must implement Promise.done
   * @return  this        Must return this to enable chaining, should you want to.
   */
  Public PromiseBase done(Promise.Done doneHandler) {
    this.doneHandler = doneHandler;
    return this;
  }

  /**
   * Execution methods:
   * These two methods both start the promise chain's execution by enqueuing the first step
   * However, the first version allows you to pass data into the first promiseStep, whereas
   * the second version accepts no params.
   */
  Public void execute(Object input) {
    dataPassthrough = input;
    System.enqueueJob(this);
  }

  Public void execute() {
    System.enqueueJob(this);
  }
}