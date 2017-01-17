/**
 * Created by kpoorman on 1/16/17.
 * Demonstrates the done, or fulfilled handler of the promise lib
 * When using the promise library, your steps must be implemented
 * as outer, independent classes.
 */

public with sharing class Demo_PromiseDone implements Promise.Done {

  // This is used to demonstrate the use of a class instance var populated by a constructor
  // Because this is an installable package i'm using an account.
  @TestVisible
  Private Account internalAccount;
  @TestVisible
  Private string completed;

  // Constructors
  public Demo_PromiseDone() {} // No op constructor
  public Demo_PromiseDone(Account incomingAccount) {
    this.internalAccount = incomingAccount;
  }

  // This is the main method that the Promise.done interface requires.
  // you could use this to persist a record, or to write a log.
  public void done(Object incomingObject) {
    // we could do nothing here - NOOP but we could also do something with the incomingObject
    if(incomingObject != null) {
      // do something here. Maybe save a record?
    }
    // this is a helper assignment to do testing of the library
    completed = 'completed';
  }

}