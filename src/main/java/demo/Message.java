package demo;
import java.io.Serializable;

public class Message implements Serializable {
    public String text;

    public Message(String text) {
        this.text = text;
    }

    public String toString() {
        return "Message{text='" + text + "'}";
    }
}