/**
 * @id java/examples/method-call
 * @name Call to method
 * @description Finds calls to com.example.Class.methodName
 * @kind path-problem
 * @problem.severity warning
 * @tags call
 *       method
 */

import java
import semmle.code.java.dataflow.DataFlow
import Flow::PathGraph

module Flow = DataFlow::Global<MyConfiguration>;


from Call c, Method m, Flow::PathNode source, Flow::PathNode sink
where
  c.getCallee().hasName("readObject") and
  m = c.getCallee() and
  Flow::flowPath(source, sink)

select
  c,
  source, sink,
  "Deserialization!info!"
  + "target" + "!"
  + m.getName() + "!"
  + m.getDeclaringType().getQualifiedName() + "!"
  + m.getDeclaringType().getQualifiedName() + "!"
  + m.getName()