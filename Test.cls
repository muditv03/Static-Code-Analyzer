public class Test {
    public void run() {
        for(Account a : [SELECT Id FROM Account]) {
            insert a;
        }
        Id accId = '0015g00000ABCDE';
    }
}
