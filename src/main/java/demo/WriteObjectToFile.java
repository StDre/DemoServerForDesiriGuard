package demo;

import java.io.*;

public class WriteObjectToFile {
    public static void main(String[] args) throws Exception {
        Message msg = new Message("Hallo vom Java‑Objekt!");

        try (ObjectOutputStream oos =
                     new ObjectOutputStream(new FileOutputStream("msg.bin"))) {
            oos.writeObject(msg);
        }

        System.out.println("Objekt geschrieben.");
    }
}