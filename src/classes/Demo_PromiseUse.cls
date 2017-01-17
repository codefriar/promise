/**
 * Created by kpoorman on 1/16/17.
 * Demonstrates the use of the Promise library
 * These methods are not required by any given interface. Each of these methods
 * exists to show how Promises are constructed, and chained, and how error / done
 * handling is done.
 *
 * Note that each of these steps are fully constructed class instances.
 * Each 'step' can accept paramters for construction like a normal class.
 * However, the results of the previous steps is depencency injected into
 * the next steps' resolve function, not the constructor.
 */

public with sharing class Demo_PromiseUse {


  // This execute method optionally accepts a string param that is used to pass data into
  // the intial promise step.
  public void execute(String param){
    if(String.isBlank(param)){
      new Promise(new Demo_PromiseStep())
        .then(new Demo_PromiseStep_Two())
        .error(new Demo_PromiseError())
        .done(new Demo_PromiseDone())
        .execute();
    } else {
      new Promise(new Demo_PromiseStep())
        .then(new Demo_PromiseStep_Two())
        .error(new Demo_PromiseError())
        .done(new Demo_PromiseDone())
        .execute(param);
    }
  }

  // This method intetntionally creates a divide by zero error so we can test handling an exception
  // note that there is no error handler defined here. The .Error() method is optional. Without it, the error
  // is just logged.
  //
  // Note! in dev and sandbox orgs the Queuable Apex queue depth is 1! as such, you're only really testing the first
  // promise step. The associated test for this method, needs to have the error occur in step 2, so thats the first
  // step we list.
  public void executeWithException() {
    new Promise(new Demo_PromiseStep_Two(0))
      .done(new Demo_PromiseDone())
      .execute();
  }

  // Like the previous method, this execution method is setup to cause a division by zero error in our
  // Demo_PromiseStep_Two's resolve method. The constructor for that class accepts a divisor, in this
  // case 0. However, this method includes an error handler. The test for this method, ensures that
  // the exception handler is invoked.
  public void executeWithExceptionWithHandler() {
    new Promise(new Demo_PromiseStep_Two(0))
      .error(new Demo_PromiseError())
      .done(new Demo_PromiseDone())
      .execute();
  }

}