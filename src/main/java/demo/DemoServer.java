package demo;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;


public class DemoServer {
    

    private static void case1(ObjectInputStream ois) throws Exception {
        Object obj = (Message) ois.readObject();
        System.out.println("case 1 - Direct cast: " + obj);
    }
    
    private static void case2(ObjectInputStream ois) throws Exception {
        Message m = (Message) ois.readObject();
        System.out.println("case 2 - Variable with type: " + m);
    }
    
    private static void case3(ObjectInputStream ois) throws Exception {
        Message m;
        m = (Message) ois.readObject();
        System.out.println("case 3 - Assignment to existing var: " + m);
    }
    
    private static void case4(ObjectInputStream ois) throws Exception {
        Object obj = ois.readObject();
        Message m = (Message) obj;
        System.out.println("case 4 - Two-step cast: " + m);
    }
    
    private static Message case5(ObjectInputStream ois) throws Exception {
        return (Message) ois.readObject();
    }
    
    public static void main(String[] args) throws Exception {
        int port = 9000;
        System.out.println("VulnServer läuft auf Port " + port);
        ServerSocket ss = new ServerSocket(port);

        while (true) {
            Socket s = ss.accept();
            System.out.println("Verbindung von " + s.getRemoteSocketAddress());
            try (ObjectInputStream ois = new ObjectInputStream(s.getInputStream())) {
                Object obj = (Message) ois.readObject();
                System.out.println("Deserialisiert: " + obj);
                
                // case1(ois);
                // case2(ois);
                // case3(ois);
                // case4(ois);
                // Message msg = case5(ois);
                // System.out.println("case 5 returned: " + msg);
            } catch (Throwable t) {
                t.printStackTrace();
            } finally {
                s.close();
            }
        }
    }
}