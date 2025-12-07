/**
 * @id java/deserialization-detection
 * @name Deserialization call detection
 * @description Detects calls to ObjectInputStream.readObject() and extracts the expected deserialized type
 * @kind problem
 * @problem.severity warning
 * @tags security
 *       deserialization
 */

import java

/**
 * Gets the type that is expected to be deserialized from a readObject call.
 * This checks:
 * 1. Cast expressions: (Message) ois.readObject()
 * 2. Variable declarations: Message m = ois.readObject()
 */
RefType getDeserializedType(MethodCall readObjectCall) {
  // Case 1: Direct cast after readObject()
  exists(CastExpr cast |
    cast.getExpr() = readObjectCall and
    result = cast.getType()
  )
  or
  // Case 2: Variable assignment with explicit type
  exists(LocalVariableDeclExpr varDecl |
    varDecl.getInit() = readObjectCall and
    result = varDecl.getVariable().getType()
  )
  or
  // Case 3: Assignment to existing variable
  exists(AssignExpr assign, Variable v |
    assign.getRhs() = readObjectCall and
    assign.getDest() = v.getAnAccess() and
    result = v.getType()
  )
}

from MethodCall readObjectCall, Method readObjectMethod, RefType targetType, Method enclosingMethod
where
  // Find calls to readObject()
  readObjectCall.getCallee() = readObjectMethod and
  readObjectMethod.hasName("readObject") and
  readObjectMethod.getDeclaringType().hasQualifiedName("java.io", "ObjectInputStream") and

  // Get the deserialized type
  targetType = getDeserializedType(readObjectCall) and

  // Get the enclosing method
  enclosingMethod = readObjectCall.getEnclosingCallable()

select
  readObjectCall,
  // Format: "Deserialization!info!<target>!<function>!<object>!<declaringType>!<method>"
  "Deserialization!info!"
  + targetType.getQualifiedName() + "!"
  + enclosingMethod.getName() + "!"
  + enclosingMethod.getDeclaringType().getQualifiedName() + "!"
  + readObjectMethod.getDeclaringType().getQualifiedName() + "!"
  + readObjectMethod.getName()
