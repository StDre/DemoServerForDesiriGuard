@echo off
set AGENT=C:/Users/drexl/OneDrive/Studium/5/ITS2/Repo/DesisriGuard-2.0/target/agent-test-1.0-SNAPSHOT-jar-with-dependencies.jar
set POLICY=%~dp0.script\policy\policy
java -javaagent:"%AGENT%=%POLICY%" -jar "%~dp0\target\DemoServer-1.0-SNAPSHOT.jar"