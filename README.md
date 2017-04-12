## Promises Redux.
When I first released the Promise library, there was a small bug. Apex wasn't reseting the DML context between promise steps. To get around this, Promise fired off each promise step through an @future method. This worked around the problem, but it did have an impact on execution time. Salesforce resolved this issue in winter '17. In repsonse, I spent some time refactoring the library. Today I'm happy to announce Promises 2.0; the AwesomeSauce edition.

## The good (what changed?)
The library no longer executes promise steps via an @future method. This can have a dramatic, positive, effect on execution times. The first version required promises to accept and return JSON Serializable objects. This new version, no longer requires anything more specific than an Object. You can pass around and return sObjects, primitives, and custom Apex objects. The biggest refactor comes from naming conventions. I established two classes in the first version: PromiseBase and Promise. I've refactored away the need for PromiseBase. Now the library, apart from examples and tests, is a single class. Additionally, I'd received some feedback suggesting 'promiseStep' needed a better name. After some discussion with other developers, I settled on 'Deferred'. Classes implementing the Deferred interface execute code via Queueable Apex. Because of this, the system defers their execution until it has resources.

## The bad (Sorry, I made a few breaking changes)
The refactoring I mentioned above meant that the API has changed. V1 and V2 are not compatible with each other. Yet, the gains provided by the changes justify the need to refactor existing promise code. To migrate to version 2, you'll need to do two things:

* Change the interface your promise classes use. From Promise.PromiseStep to Promise.deferred.</li>
* Remove references to SerializableData. Either by passing specific object types, or by accepting and returning generic Objects

Below is a full example class that uses promises v2.0 - _AwesomeSauce Edition_

```apex
/**
 * Promise v2.0 - Kevin Poorman
 * Thanks to Chuck Jonas!
 * This class exists to demonstrate the usage of the Promise library.
 *
 */
Public Class Demo_PromiseUse {
  // This execute method optionally accepts a string param that is used to pass data into
  // the intial promise step.
  Public Void execute(String param) {
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
  Public Void executeWithException() {
    new Promise(new Demo_PromiseStep_Two(0))
      .done(new Demo_PromiseDone())
      .execute();
  }

  // Like the previous method, this execution method is setup to cause a division by zero error in our
  // Demo_PromiseStep_Two's resolve method. The constructor for that class accepts a divisor, in this
  // case 0. However, this method includes an error handler. The test for this method, ensures that
  // the exception handler is invoked.
  Public Void executeWithExceptionWithHandler() {
    new Promise(new Demo_PromiseStep_Two(0))
      .error(new Demo_PromiseError())
      .done(new Demo_PromiseDone())
      .execute();
  }

  //   ____        __                        _  ____ _
  //  |  _ \  ___ / _| ___ _ __ _ __ ___  __| |/ ___| | __ _ ___ ___  ___ ___
  //  | | | |/ _ \ |_ / _ \ '__| '__/ _ \/ _` | |   | |/ _` / __/ __|/ _ \ __|
  //  | |_| |  __/  _|  __/ |  | | |  __/ (_| | |___| | (_| \__ \__ \  __\__ \
  //  |____/ \___|_|  \___|_|  |_|  \___|\__,_|\____|_|\__,_|___/___/\___|___/
  //

  Public Class Demo_PromiseStep implements Promise.Deferred {

    @TestVisible
    Private Integer checkInteger; // helpful for testing. not generally needed.
    // this is the required method for a PromiseStep class.
    Public Object resolve(Object incomingObject) {
      // Do some aysnchronous work, in this case, we'll pretend it's in
      // our helper method:
      checkInteger = exampleHelperMethod();
      return checkInteger;
    }

    // helper methods
    // I put this in a helper method not out of neccessity but because it illustrates that
    // this is a normal class, and you can have multiple methods and architect this class
    // in a way that code is easily testable, and isolated.
    private Integer exampleHelperMethod() {
      return Crypto.getRandomInteger();
    }

  }

  Public Class Demo_PromiseStep_Two implements Promise.Deferred {
    @TestVisible
    Private Integer dataPassedIn;
    @TestVisible
    Private Integer slowAsyncWork;
    Private Integer divisor;

    Public Demo_PromiseStep_Two() {
    }
    // this constructor exists to facilitate testing. By accepting an integer
    // i can later cause a division by zero error that is used to test error
    // handling in the framework.
    Public Demo_PromiseStep_Two(Integer divisor) {
      this.divisor = divisor;
    }

    // This is the required interface method for a PromiseStep
    Public Object resolve(Object incomingObject) {
      // Do some aysnchronous work, in this case, we'll pretend it's in our helper method:
      if (incomingObject != null) {
        this.dataPassedIn = (Integer) incomingObject;
      }
      //intentionally setup to cause a divide by 0 error
      if (this.divisor != null) {
        Integer thrown = 1 / this.divisor;
      }

      slowAsyncWork = exampleHelperMethod();
      return slowAsyncWork;
    }

    // helper methods
    private Integer exampleHelperMethod() {
      return Crypto.getRandomInteger();
    }

  }

  //   _   _                 _ _            ____ _
  //  | | | | __ _ _ __   __| | | ___ _ __ / ___| | __ _ ___ ___  ___ ___
  //  | |_| |/ _` | '_ \ / _` | |/ _ \ '__| |   | |/ _` / __/ __|/ _ \ __|
  //  |  _  | (_| | | | | (_| | |  __/ |  | |___| | (_| \__ \__ \  __\__ \
  //  |_| |_|\__,_|_| |_|\__,_|_|\___|_|   \____|_|\__,_|___/___/\___|___/
  //

  public class Demo_PromiseDone implements Promise.Done {
    // This is used to demonstrate the use of a class instance var populated by a constructor
    // Because this is an installable package i'm using an account.
    @TestVisible
    Private Account internalAccount;
    @TestVisible
    Private string completed;

    // Constructors
    public Demo_PromiseDone() {
    } // No op constructor
    public Demo_PromiseDone(Account incomingAccount) {
      this.internalAccount = incomingAccount;
    }

    // This is the main method that the Promise.done interface requires.
    // you could use this to persist a record, or to write a log.
    Public Void done(Object incomingObject) {
      // we could do nothing here - NOOP but we could also do something with the incomingObject
      if (incomingObject != null) {
        // do something here. Maybe save a record?
      }
      // this is a helper assignment to do testing of the library
      completed = 'completed';
    }
  }

  Public Class Demo_PromiseError implements Promise.Error {
    @TestVisible
    private String errorMessage;

    public Demo_PromiseError() {
    }
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

      return e;
    }
  }
  
}
```

## Straight up now tell me, if you're using this lib!
Since I released the library I've talked to many developers who are using it. They've discovered a few new use cases that I'd not thought of. For instance, one developer is using Promises in Sandbox startup scripts. This helps his company ensure the order of sandbox data creation. They have many address validations, callouts and integrations during the creation of accounts. Creating those accounts, and processing the integrations must finish first. Until then, creating dependent objects will fail. Another developer is using promises to automate a SAAS company's billing. Harnessing promises, she was able to write a single chain of steps. Promises enables them to retry callout steps when an integration stops responding. Steps exist to create a case when the payment processor declines a card. When finished, the process sends the customer an receipt. Super cool. If you're using Promise, or have an interesting use case for promises, drop me a line.

## Installation
<a href="https://githubsfdeploy.herokuapp.com?owner=codefriar&repo=promise">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>
