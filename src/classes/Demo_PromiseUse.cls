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
      // Your return value just be serializable as JSON, and you have to pass
      // both the object, and it's class
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
      // Your return value just be serializable as JSON, and you have to pass
      // both the object, and it's class
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