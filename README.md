# Promise

A simple promise library for Apex (Salesforce)

Thanks and shout out to Chuck Jonas https://github.com/ChuckJonas
who wrote a more feature-rich implementation of the promise pattern in called Apex-Q which can be found here: https://github.com/ChuckJonas/APEX-Q I chose to simplify his work for demonstration and teaching purposes by forcing all promises to execute in a @future context. Other small changes and tests have been added.

## Why would you do such a thing?

Promises are a powerful pattern for handling asynchronous execution. They allow a developer to specify a sequence of operations that have to take place in a given order, without specifying how long each step takes.

## Say what?
The classic example of Promise pattern use is for callouts to external services. You have some code that requires interacting with a third party service.
Unfortunately, that code can take 10ms or 30sec to run. By isolating that code into a promise you can ensure that this promise will resolve before the next block of code is executed.

## Caveats and notes:
* This library treats all promises the same, forcing them to execute through an @future method. If you'd like to use a similar library without that restriction, see https://github.com/ChuckJonas/APEX-Q
* The done handler will be called regardless of whether an exception has been thrown.
* All classes implementing the Promise.PromiseStep, Promise.Error and Promise.Done interfaces must be top-level classes.
* All resolve methods must return a Promise.SerializableData object, which means all resolve methods must return an object capable of being represented in JSON.
* This has a high degree of code coverage and is in production use. However, you must implement and use this at your own risk. If this somehow results in a kitten being launched from your office microwave everytime someone submits a new opportunity, that's on you.

## How do I use this amazing thing?
1. First, identify the steps in your workflow.
2. Create a class that implements the Promise.PromiseStep interface for each step in your workflow. Each class' resolve method is responsible for doing any async work such as callouts etc. Note that the framework will call each steps' resolve method with a parameter that is the result of the previous steps' resolve method.
3. Where you want to start the execution of your promise chain, implement code similar to this:
```apex
new Promise(new Demo_PromiseStep())
        .then(new Demo_PromiseStep_Two())
        .error(new Demo_PromiseError())
        .done(new Demo_PromiseDone())
        .execute(param);
```

## Installation
