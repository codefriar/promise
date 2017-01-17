/**
 * Created by kpoorman on 1/16/17.
 * Like the Demo_PromiseSTep class, this class demonstrates how to create and use a promise step
 * This one contains a constructor, and some private variables just for the sake of testing.
 * This class is intended as both demonstration, and a testing foil for the framework.
 */

public with sharing class Demo_PromiseStep_Two implements Promise.PromiseStep{

  @TestVisible
  Private Integer dataPassedIn;
  @TestVisible
  Private Integer slowAsyncWork;
  Private Integer divisor;

  Public Demo_PromiseStep_Two(){}
  // this constructor exists to facilitate testing. By accepting an integer
  // i can later cause a division by zero error that is used to test error
  // handling in the framework.
  Public Demo_PromiseStep_Two(Integer divisor){
    this.divisor = divisor;
  }

  // This is the required interface method for a PromiseStep
  Public Promise.SerializableData resolve(Object incomingObject){
    // Do some aysnchronous work, in this case, we'll pretend it's in our helper method:
    if(incomingObject != null) {
      this.dataPassedIn = (Integer) incomingObject;
    }
    //intentionally setup to cause a divide by 0 error
    if(this.divisor != null) {
      Integer thrown = 1 / this.divisor;
    }

    slowAsyncWork = exampleHelperMethod();
    // Your return value just be serializable as JSON, and you have to pass
    // both the object, and it's class
    return new Promise.SerializableData(slowAsyncWork, Integer.class);
  }

  // helper methods
  private Integer exampleHelperMethod(){
    return Crypto.getRandomInteger();
  }

}