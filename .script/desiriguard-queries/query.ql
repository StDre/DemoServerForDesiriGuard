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
  // Direct cast after readObject()
  exists(CastExpr cast |
    cast.getExpr() = readObjectCall and
    result = cast.getType()
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
