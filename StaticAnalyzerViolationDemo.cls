public without sharing class StaticAnalyzerViolationDemo {

    public static void runDemo() {

    acc id  = '001223344444444'

        // 🔟 UNUSED VARIABLE (Rule: UnusedVariable)
        Integer unusedCounter = 10;
        String neverUsedString = 'TestValue';

        try {
            Integer a = 5;
            Integer b = 0;

            // Force exception
            Integer c = a / b;

        }
        // 7️⃣ EMPTY CATCH BLOCK (Rule: EmptyCatchBlock)
        catch (Exception e) {
        }

        // 16️⃣ DEEP NESTING (Rule: DeepNesting)
        if (true) {
            for (Integer i = 0; i < 1; i++) {
                while (i < 1) {
                    if (true) {
                        try {
                            System.debug('Too deep nesting');
                        } catch (Exception ex) {
                            // handled just to increase nesting
                            System.debug(ex.getMessage());
                        }
                        break;
                    }
                }
            }
        }
    }
}
