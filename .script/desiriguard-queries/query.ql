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

RefType getDeserializedType(MethodCall readObjectCall) {
  // Case 1: Direct cast after readObject()
  exists(CastExpr cast |
    cast.getExpr() = readObjectCall and
    result = cast.getType()
  )
  or
  // Case 2: Variable assignment with explicit non-Object type
  exists(LocalVariableDeclExpr varDecl |
    varDecl.getInit() = readObjectCall and
    result = varDecl.getVariable().getType() and
    not result.hasQualifiedName("java.lang", "Object")
  )
  or
  // Case 3: Assignment to existing variable with non-Object type
  exists(AssignExpr assign, Variable v |
    assign.getRhs() = readObjectCall and
    assign.getDest() = v.getAnAccess() and
    result = v.getType() and
    not result.hasQualifiedName("java.lang", "Object")
  )
  or
  // Case 4: Subsequent cast on the variable that holds readObject() result
  // Pattern: Object obj = ois.readObject(); Message m = (Message) obj;
  exists(LocalVariableDeclExpr varDecl, Variable var, CastExpr cast |
    varDecl.getInit() = readObjectCall and
    var = varDecl.getVariable() and
    cast.getExpr() = var.getAnAccess() and
    result = cast.getType() and
    not result.hasQualifiedName("java.lang", "Object")
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
