package demo;

import java.io.*;
import java.net.ServerSocket;
import java.net.Socket;


public class DemoServer {
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
            } catch (Throwable t) {
                t.printStackTrace();
            } finally {
                s.close();
            }
        }
    }
}