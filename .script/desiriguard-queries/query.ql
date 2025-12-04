/**
 * @id java/examples/method-call
 * @name Call to method
 * @description Finds calls to com.example.Class.methodName
 * @kind problem
 * @problem.severity warning
 * @tags call
 *       method
 */
 // Wichtig bei kind entweder problem oder path-problem, eig mit path aber da bekommen wieder so viele fehler die net dfixen kann weil dann wieder import problem

 //Wichtig hier nur Java
import java

//keien Ahnung wieso hier die anderen net gehen
from Call c, Method m
where
  c.getCallee().hasName("readObject") and
  m = c.getCallee()

select
  c,
  // Python‑Script erwartet folgendes Format:
  // "Deserialization!info!<target>!<function>!<object>!<declaringType>!<method>"
  "Deserialization!info!"
  + "demo.Message" + "!"
  + m.getName() + "!"
  + m.getDeclaringType().getQualifiedName() + "!"
  + m.getDeclaringType().getQualifiedName() + "!"
  + m.getName()