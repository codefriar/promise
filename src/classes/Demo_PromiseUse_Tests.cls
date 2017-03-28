@isTest
private class Demo_PromiseUse_Tests {
  static testMethod void test_Demo_PromiseStep(){
    Test.startTest();
    Demo_PromiseUse.Demo_PromiseStep ds = new Demo_PromiseUse.Demo_PromiseStep();
    Object results = ds.resolve(null);
    Test.stopTest();
    Integer expected = ds.checkInteger;
    Integer check = (Integer) results;
    System.assertEquals(expected, check, 'these should match');
  }

  static testMethod void test_Demo_PromiseStep_Two(){
    Test.startTest();
    Demo_PromiseUse.Demo_PromiseStep_Two ds = new Demo_PromiseUse.Demo_PromiseStep_Two();
    Object results = ds.resolve(33);
    Test.stopTest();
    System.assertEquals(ds.dataPassedIn, 33, 'Data passed in should match 33');
    Integer expected = ds.slowAsyncWork;
    Integer check = (Integer) results;
    System.assertEquals(expected, check, 'these should match');
  }

  static testmethod void test_Demo_PromiseError(){
    Demo_PromiseUse.Demo_PromiseError pe = new Demo_PromiseUse.Demo_PromiseError();
    String match;
    Test.startTest();
    try{
      integer i = 1/0;
    } catch (Exception e){
      pe.error(e);
      match = pe.errorMessage;
    }
    Test.stopTest();
    system.assertNotEquals(null, match, 'Match should exist');
  }

  static testMethod void test_Demo_PromiseDone() {
    Demo_PromiseUse.Demo_PromiseDone p = new Demo_PromiseUse.Demo_PromiseDone();
    system.assertNotEquals(null, p, 'expected p to be a valid object');
  }

  static testMethod void test_Demo_Done_Account_constructor(){
    Account a = new account(name='foo for test');
    Test.startTest();
    Demo_PromiseUse.Demo_PromiseDone pd = new Demo_PromiseUse.Demo_PromiseDone(a);
    pd.done('done');
    Test.stopTest();
    system.assertEquals(a.name, pd.internalAccount.name, 'expected the accounts to match');
    system.assertEquals('completed', pd.completed, 'expected this to be completed');
  }

  static testMethod void test_DemoPromiseUse_execute(){
    Demo_PromiseUse dpu = new Demo_PromiseUse();
    Test.startTest();
    dpu.execute('');
    Test.stopTest();
  }

  static testMethod void test_DemoPromiseUse_execute_W_Param(){
    Demo_PromiseUse dpu = new Demo_PromiseUse();
    Test.startTest();
    dpu.execute('foo');
    Test.stopTest();
  }

  static testMethod void test_Demo_PromiseStep_Two_throws_exception(){
    Boolean didFail = false;
    Demo_PromiseUse dpu = new Demo_PromiseUse();
    try{
      Test.startTest();
      dpu.executeWithException();
      Test.stopTest();
    } catch (Exception e){
      didFail = true;
    }
    System.assert(didFail);
  }

  static testMethod void test_Demo_PromiseStep_Two_throws_exception_W_handler(){
    Demo_PromiseUse dpu = new Demo_PromiseUse();
    Test.startTest();
    // unintutively the exception is swallowed by the error handler so this has to be a positive test!
    dpu.executeWithExceptionWithHandler();
    Test.stopTest();
  }
}