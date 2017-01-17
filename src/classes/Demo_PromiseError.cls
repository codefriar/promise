/**
 * Created by kpoorman on 1/16/17.
 * Demonstrates the Error Handling capabilities of the Promise lib
 * Because these classes are Enqueued in an @future context, the
 * various steps, done and error handlers all must be outer classes
 */

public with sharing class Demo_PromiseError implements Promise.Error {
  @TestVisible
  private String errorMessage;

  public Demo_PromiseError() {}

  // This is the main interface method that you must implement
  // note that it does have a return type, and in this case I'm using the
  // promise.serializableData type. This will pass the 'error occured' string to the done handler
  public Object error(Exception e) {
    //for now, just dump it to the logs
    system.debug('Error Handler received the following exception ' + e.getmessage() + '\n\n' + e.getStackTraceString());
    //Make the error available for testing.
    this.errorMessage = e.getMessage();
    //Alternatively, you could do any number of things with this exception like:
    // 1. retry the promise chain. For instance, if an external service returns a temp error, retry
    // 1a. Use the flow control object to cap the retry's
    // 2. log the error to a UI friendly reporting object or audit log
    // 3. Email the error report, and related objects to the affected users
    // 4. post something to chatter.

    //return null here, so that the done handler will run but without data
    return new Promise.SerializableData('Error Occured', String.class);
  }
}