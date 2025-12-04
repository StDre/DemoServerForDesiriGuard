package demo;

import java.io.*;

public class WriteObjectToFile {
    public static void main(String[] args) throws Exception {
        FalseMessage msg = new FalseMessage("Hallo vom Java‑Objekt!");

        try (ObjectOutputStream oos =
                     new ObjectOutputStream(new FileOutputStream("false_msg.bin"))) {
            oos.writeObject(msg);
        }

        System.out.println("Objekt geschrieben.");
    }
}