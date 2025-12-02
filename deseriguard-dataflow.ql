/**
 * @name DeseriGuard Policy Extraction Query
 * @description Produces cast types, object names and deserializer info
 *              in the exact message format expected by the DeseriGuard policy generator.
 * @kind path-problem
 */

import java
import DataFlow::PathGraph

/**
 * ❶ SOURCE: user-controlled data flowing into ObjectInputStream, XMLDecoder, XStream,...
 */
class DeserSource extends DataFlow::SourceNode {
  DeserSource() {
    exists(MethodAccess ma |
      ma.getMethod().getName() = "getInputStream" or
      ma.getMethod().getName() = "readLine"
    |
      this.asExpr() = ma
    )
  }
}

/**
 * ❷ SINK: All deserialization entry points
 */
class DeserSink extends DataFlow::SinkNode {
  DeserSink() {
    exists(MethodAccess ma |
      (
        // JDK OIS
        ma.getMethod().getDeclaringType().hasQualifiedName("java.io","ObjectInputStream")
        or
        // SafeObjectInputStream (OfBiz)
        ma.getMethod().getDeclaringType().hasQualifiedName("org.apache.ofbiz.base.util","SafeObjectInputStream")
        or
        // XMLDecoder
        ma.getMethod().getDeclaringType().hasQualifiedName("java.beans","XMLDecoder")
        or
        // XStream
        ma.getMethod().getDeclaringType().getName() = "XStream"
      )
      and ma.getMethod().getName() = "readObject" or ma.getMethod().getName() = "fromXML"
    |
      this.asExpr() = ma
    )
  }
}

/**
 * ❸ Helper: Try to find nearby cast types and instanceof operands
 */
string getCastType(Expr e) {
  result = e.getParent().(CastExpr).getType().getQualifiedName()
}

string getInstanceOfType(Expr e) {
  result = e.getParent().(InstanceOfExpr).getTestedType().getQualifiedName()
}

/**
 * ❹ Helper: Find object variable name
 */
string getObjectName(Expr e) {
  result = e.toString()
}

/**
 * ❺ Helper: Extract deserializer class/method
 */
string getDeserializerClass(DeserSink sink) {
  result = sink.getNode().(MethodAccess).getMethod().getDeclaringType().getQualifiedName()
}

string getDeserializerMethod(DeserSink sink) {
  result = sink.getNode().(MethodAccess).getMethod().getName()
}

from DeserSource src, DeserSink sink, DataFlow::PathNode sourceNode, DataFlow::PathNode sinkNode
where DataFlow::flowPath(sourceNode, sinkNode)
  and sourceNode = src
  and sinkNode = sink
select
  sinkNode.getNode().getLocation(),
  // -------------- IMPORTANT: EXACT MESSAGE FORMAT --------------
  // Format:
  // !<TargetType>!<FunctionName>!<ObjectName>!<DeserializerClass>!<DeserializerMethod>!
  "!" +
  getCastType(sourceNode.getNode()) + "!" +
  sourceNode.getNode().getEnclosingCallable().getName() + "!" +
  getObjectName(sourceNode.getNode()) + "!" +
  getDeserializerClass(sink) + "!" +
  getDeserializerMethod(sink) + "!"
